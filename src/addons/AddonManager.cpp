#include "addons/AddonManager.h"

#include "app/Paths.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJSEngine>
#include <QLoggingCategory>
#include <QRegularExpression>
#include <QQmlEngine>
#include <QUuid>

#include <algorithm>
#include <functional>

namespace swiftify {

Q_LOGGING_CATEGORY(lcAddons, "swiftify.addons")

AddonManager *AddonManager::s_instance = nullptr;

namespace {

const QRegularExpression kIdPattern(QStringLiteral("^[a-z0-9]+(?:[.-][a-z0-9]+)*$"));
const QRegularExpression kSlotPattern(QStringLiteral("^[a-z][A-Za-z0-9]{0,47}$"));
const QRegularExpression kVersionPattern(QStringLiteral("^[0-9]+\\.[0-9]+\\.[0-9]+(?:[-+][A-Za-z0-9.-]+)?$"));
constexpr qsizetype kManifestLimit = 64 * 1024;
constexpr qsizetype kPackageLimit = 32 * 1024 * 1024;
constexpr int kFileLimit = 512;
constexpr int kExtensionLimit = 16;

QString normalizedRelativePath(QString path)
{
    path.replace(u'\\', u'/');
    return QDir::cleanPath(path);
}

bool isSafeRelativePath(const QString &path)
{
    if (path.isEmpty() || QDir::isAbsolutePath(path) || path.contains(u':')) return false;
    const QString normalized = normalizedRelativePath(path);
    return normalized != QLatin1StringView(".") && normalized != QLatin1StringView("..")
        && !normalized.startsWith(QLatin1StringView("../")) && !normalized.startsWith(u'/');
}

bool pathIsWithin(const QString &root, const QString &candidate)
{
    QString normalizedRoot = QDir::fromNativeSeparators(QDir::cleanPath(root));
    QString normalizedCandidate = QDir::fromNativeSeparators(QDir::cleanPath(candidate));
#ifdef Q_OS_WIN
    normalizedRoot = normalizedRoot.toCaseFolded();
    normalizedCandidate = normalizedCandidate.toCaseFolded();
#endif
    if (!normalizedRoot.endsWith(u'/')) normalizedRoot += u'/';
    return normalizedCandidate.startsWith(normalizedRoot);
}

bool isResourcePath(const QString &path)
{
    return path.startsWith(QLatin1StringView(":/"));
}

} // namespace

AddonManager::AddonManager(QObject *parent)
    : QObject(parent)
    , m_installDirectory(QDir(paths::dataDirectory()).filePath(QStringLiteral("addons")))
    , m_store(std::make_unique<QSettings>(QSettings::IniFormat, QSettings::UserScope,
                                          QStringLiteral("Swiftify"), QStringLiteral("Swiftify")))
{
    if (!s_instance) s_instance = this;
    QDir().mkpath(m_installDirectory);
    reload();
}

AddonManager::AddonManager(const QString &installDirectory, const QString &settingsFile, QObject *parent)
    : QObject(parent)
    , m_installDirectory(QDir::cleanPath(installDirectory))
    , m_store(std::make_unique<QSettings>(settingsFile, QSettings::IniFormat))
{
    if (!s_instance) s_instance = this;
    QDir().mkpath(m_installDirectory);
    reload();
}

AddonManager::~AddonManager()
{
    if (s_instance == this) s_instance = nullptr;
}

AddonManager *AddonManager::create(QQmlEngine *, QJSEngine *)
{
    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
    return s_instance;
}

QVariantMap AddonManager::asVariant(const Addon &addon) const
{
    QVariantList extensions;
    QStringList slotNames;
    extensions.reserve(addon.extensions.size());
    for (const Extension &extension : addon.extensions) {
        extensions.append(QVariantMap {
            {QStringLiteral("slot"), extension.slot},
            {QStringLiteral("entryPoint"), QUrl::fromLocalFile(extension.entryPoint)}});
        if (!slotNames.contains(extension.slot)) slotNames.append(extension.slot);
    }
    return {{QStringLiteral("id"), addon.id},
            {QStringLiteral("name"), addon.name},
            {QStringLiteral("version"), addon.version},
            {QStringLiteral("description"), addon.description},
            {QStringLiteral("slots"), slotNames},
            {QStringLiteral("extensions"), extensions},
            {QStringLiteral("enabled"), addon.enabled},
            {QStringLiteral("bundled"), addon.bundled}};
}

QVariantList AddonManager::installedAddons() const
{
    QList<Addon> sorted = m_installed.values();
    std::sort(sorted.begin(), sorted.end(), [](const Addon &left, const Addon &right) {
        return left.name.compare(right.name, Qt::CaseInsensitive) < 0;
    });
    QVariantList result;
    result.reserve(sorted.size());
    for (const Addon &addon : sorted) result.append(asVariant(addon));
    return result;
}

QVariantList AddonManager::availableAddons() const
{
    QVariantList result;
    const QDir bundled(QStringLiteral(":/addons"));
    const QStringList directories = bundled.entryList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks, QDir::Name);
    for (const QString &directory : directories) {
        Addon addon;
        QString error;
        if (!readManifest(bundledDirectory(directory), addon, error) || m_installed.contains(addon.id)) continue;
        addon.bundled = true;
        QStringList slotNames;
        for (const Extension &extension : addon.extensions) {
            if (!slotNames.contains(extension.slot)) slotNames.append(extension.slot);
        }
        result.append(QVariantMap {
            {QStringLiteral("id"), addon.id},
            {QStringLiteral("name"), addon.name},
            {QStringLiteral("version"), addon.version},
            {QStringLiteral("description"), addon.description},
            {QStringLiteral("slots"), slotNames},
            {QStringLiteral("bundled"), true}});
    }
    return result;
}

QVariantMap AddonManager::addon(const QString &id) const
{
    const auto it = m_installed.constFind(id);
    return it == m_installed.cend() ? QVariantMap {} : asVariant(*it);
}

QString AddonManager::installBundled(const QString &id)
{
    if (!kIdPattern.match(id).hasMatch()) return tr("That add-on ID is not valid.");
    const QString source = bundledDirectory(id);
    Addon bundled;
    QString error;
    if (!readManifest(source, bundled, error)) return error;
    if (bundled.id != id) return tr("The bundled add-on ID does not match its folder.");
    return installPackage(source, true);
}

QString AddonManager::installFromFolder(const QUrl &folderUrl)
{
    if (!folderUrl.isLocalFile()) return tr("Choose a local add-on folder first.");
    const QString folder = QDir::cleanPath(folderUrl.toLocalFile());
    if (folder.isEmpty()) return tr("Choose an add-on folder first.");
    return installPackage(folder, false);
}

void AddonManager::setEnabled(const QString &id, bool enabled)
{
    auto it = m_installed.find(id);
    if (it == m_installed.end() || it->enabled == enabled) return;
    it->enabled = enabled;
    if (!enabled && m_activeMiniPlayerId == id) closeMiniPlayer();
    m_store->setValue(enabledKey(id), enabled);
    m_store->sync();
    emit addonsChanged();
}

QString AddonManager::remove(const QString &id)
{
    const auto it = m_installed.constFind(id);
    if (it == m_installed.cend()) return tr("That add-on is not installed.");
    const QString name = it->name;
    const QString target = QDir(m_installDirectory).filePath(id);
    if (QFileInfo(target).isSymLink() || !QDir(target).removeRecursively()) {
        return tr("Could not remove %1.").arg(name);
    }
    if (m_activeMiniPlayerId == id) closeMiniPlayer();
    m_store->remove(enabledKey(id));
    m_store->sync();
    reload();
    return tr("Removed %1.").arg(name);
}

bool AddonManager::openMiniPlayer(const QString &id)
{
    const auto it = m_installed.constFind(id);
    if (it == m_installed.cend() || !it->enabled || !hasSlot(*it, QStringLiteral("miniPlayer"))) return false;
    if (m_activeMiniPlayerId == id) {
        emit miniPlayerChanged();
        return true;
    }
    m_activeMiniPlayerId = id;
    emit miniPlayerChanged();
    return true;
}

void AddonManager::closeMiniPlayer()
{
    if (m_activeMiniPlayerId.isEmpty()) return;
    m_activeMiniPlayerId.clear();
    emit miniPlayerChanged();
}

QVariantList AddonManager::enabledForSlot(const QString &slot) const
{
    QVariantList result;
    for (const Addon &addon : m_installed) {
        if (!addon.enabled) continue;
        for (const Extension &extension : addon.extensions) {
            if (extension.slot != slot) continue;
            result.append(QVariantMap {
                {QStringLiteral("id"), addon.id},
                {QStringLiteral("name"), addon.name},
                {QStringLiteral("version"), addon.version},
                {QStringLiteral("description"), addon.description},
                {QStringLiteral("slot"), extension.slot},
                {QStringLiteral("entryPoint"), QUrl::fromLocalFile(extension.entryPoint)}});
        }
    }
    return result;
}

QString AddonManager::bundledDirectory(const QString &id) const
{
    return QStringLiteral(":/addons/") + id;
}

QString AddonManager::enabledKey(const QString &id) const
{
    return QStringLiteral("addons/%1/enabled").arg(id);
}

bool AddonManager::hasSlot(const Addon &addon, const QString &slot) const
{
    return std::any_of(addon.extensions.cbegin(), addon.extensions.cend(), [&](const Extension &extension) {
        return extension.slot == slot;
    });
}

bool AddonManager::readManifest(const QString &directory, Addon &addon, QString &error) const
{
    const QFileInfo directoryInfo(directory);
    if (!directoryInfo.isDir() || directoryInfo.isSymLink()) {
        error = tr("The selected folder is not a regular add-on folder.");
        return false;
    }

    QFile file(QDir(directory).filePath(QStringLiteral("manifest.json")));
    if (!file.open(QIODevice::ReadOnly) || file.size() <= 0 || file.size() > kManifestLimit) {
        error = tr("The add-on needs a small manifest.json file.");
        return false;
    }
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        error = tr("The add-on manifest is not valid JSON.");
        return false;
    }

    const QJsonObject object = document.object();
    const QString id = object.value(QStringLiteral("id")).toString();
    const QString name = object.value(QStringLiteral("name")).toString().trimmed();
    const QString version = object.value(QStringLiteral("version")).toString();
    const QString description = object.value(QStringLiteral("description")).toString().trimmed();
    const QJsonArray extensions = object.value(QStringLiteral("extensions")).toArray();
    const int apiVersion = object.value(QStringLiteral("apiVersion")).toInt(-1);

    if (!kIdPattern.match(id).hasMatch() || id.size() > 64) {
        error = tr("The add-on ID must use lowercase letters, numbers, dots, and dashes.");
        return false;
    }
    if (name.isEmpty() || name.size() > 80 || description.size() > 500
        || !kVersionPattern.match(version).hasMatch()) {
        error = tr("The add-on name, version, or description is not valid.");
        return false;
    }
    if (apiVersion != kApiVersion) {
        error = tr("This add-on targets API %1; this Blood Moon build supports API %2.").arg(apiVersion).arg(kApiVersion);
        return false;
    }
    if (extensions.isEmpty() || extensions.size() > kExtensionLimit) {
        error = tr("An add-on needs between one and %1 extensions.").arg(kExtensionLimit);
        return false;
    }

    const bool resource = isResourcePath(directory);
    const QString canonicalDirectory = resource ? QString() : directoryInfo.canonicalFilePath();
    if (!resource && canonicalDirectory.isEmpty()) {
        error = tr("The add-on folder could not be resolved safely.");
        return false;
    }

    QList<Extension> parsedExtensions;
    for (const QJsonValue &value : extensions) {
        if (!value.isObject()) {
            error = tr("An add-on extension must be an object.");
            return false;
        }
        const QJsonObject item = value.toObject();
        const QString slot = item.value(QStringLiteral("slot")).toString();
        const QString entry = item.value(QStringLiteral("entryPoint")).toString();
        if (!kSlotPattern.match(slot).hasMatch()) {
            error = tr("An add-on extension point name is not valid.");
            return false;
        }
        if (!isSafeRelativePath(entry) || !entry.endsWith(QLatin1StringView(".qml"), Qt::CaseInsensitive)) {
            error = tr("An add-on entry point must be a relative QML file.");
            return false;
        }

        const QString resolvedEntry = QDir(directory).filePath(normalizedRelativePath(entry));
        const QFileInfo entryInfo(resolvedEntry);
        if (!entryInfo.isFile() || entryInfo.isSymLink()) {
            error = tr("An add-on entry point could not be found as a regular file.");
            return false;
        }
        QString entryPoint = entryInfo.absoluteFilePath();
        if (!resource) {
            entryPoint = entryInfo.canonicalFilePath();
            if (entryPoint.isEmpty() || !pathIsWithin(canonicalDirectory, entryPoint)) {
                error = tr("An add-on entry point must stay inside its package folder.");
                return false;
            }
        }

        const bool duplicate = std::any_of(parsedExtensions.cbegin(), parsedExtensions.cend(),
            [&](const Extension &extension) { return extension.slot == slot && extension.entryPoint == entryPoint; });
        if (duplicate) {
            error = tr("The add-on lists the same extension more than once.");
            return false;
        }
        parsedExtensions.append({slot, entryPoint});
    }

    addon.id = id;
    addon.name = name;
    addon.version = version;
    addon.description = description;
    addon.extensions = parsedExtensions;
    return true;
}

QString AddonManager::installPackage(const QString &source, bool bundled)
{
    Addon incoming;
    QString error;
    if (!readManifest(source, incoming, error)) return error;

    const QString target = QDir(m_installDirectory).filePath(incoming.id);
    const QString suffix = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const QString staging = QDir(m_installDirectory).filePath(QStringLiteral(".%1.installing-%2").arg(incoming.id, suffix));
    const QString backup = QDir(m_installDirectory).filePath(QStringLiteral(".%1.backup-%2").arg(incoming.id, suffix));
    const QString sourceRoot = QFileInfo(source).canonicalFilePath();
    if (!isResourcePath(source) && !sourceRoot.isEmpty() && pathIsWithin(sourceRoot, staging)) {
        return tr("Choose a package folder outside Blood Moon's add-on install folder.");
    }
    if (!copyPackage(source, staging, error)) {
        QDir(staging).removeRecursively();
        return error;
    }
    Addon staged;
    if (!readManifest(staging, staged, error)) {
        QDir(staging).removeRecursively();
        return error;
    }
    if (QFileInfo(target).isSymLink()) {
        QDir(staging).removeRecursively();
        return tr("The existing add-on folder is not safe to replace.");
    }
    if (QDir(target).exists() && !QDir().rename(target, backup)) {
        QDir(staging).removeRecursively();
        return tr("Could not prepare the existing add-on for replacement.");
    }
    if (!QDir().rename(staging, target)) {
        if (QDir(backup).exists()) QDir().rename(backup, target);
        QDir(staging).removeRecursively();
        return tr("Could not install %1.").arg(incoming.name);
    }
    if (QDir(backup).exists()) QDir(backup).removeRecursively();

    if (m_activeMiniPlayerId == incoming.id) closeMiniPlayer();
    m_store->setValue(enabledKey(incoming.id), true);
    m_store->sync();
    reload();
    qCInfo(lcAddons) << "Installed add-on" << incoming.id << "from" << (bundled ? "the app bundle" : "a selected folder");
    return tr("Installed %1.").arg(incoming.name);
}

bool AddonManager::copyPackage(const QString &source, const QString &destination, QString &error) const
{
    int files = 0;
    qint64 bytes = 0;
    std::function<bool(const QString &, const QString &)> copyDirectory;
    copyDirectory = [&](const QString &from, const QString &to) {
        const QFileInfo sourceInfo(from);
        if (sourceInfo.isSymLink() || !sourceInfo.isDir() || !QDir().mkpath(to)) {
            error = tr("Could not create or safely read the add-on install folder.");
            return false;
        }
        const QFileInfoList entries = QDir(from).entryInfoList(
            QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden, QDir::Name);
        for (const QFileInfo &entry : entries) {
            const QString target = QDir(to).filePath(entry.fileName());
            if (entry.isSymLink()) {
                error = tr("Add-ons cannot contain symbolic links.");
                return false;
            }
            if (entry.isDir()) {
                if (!copyDirectory(entry.absoluteFilePath(), target)) return false;
                continue;
            }
            if (!entry.isFile() || ++files > kFileLimit || (bytes += entry.size()) > kPackageLimit) {
                error = tr("The add-on has too many files or is larger than 32 MB.");
                return false;
            }
            if (!QFile::copy(entry.absoluteFilePath(), target)) {
                error = tr("Could not copy %1 into the add-on folder.").arg(entry.fileName());
                return false;
            }
        }
        return true;
    };
    return copyDirectory(source, destination);
}

void AddonManager::reload()
{
    m_installed.clear();
    const QDir directory(m_installDirectory);
    const QFileInfoList entries = directory.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::NoSymLinks, QDir::Name);
    for (const QFileInfo &entry : entries) {
        Addon addon;
        QString error;
        if (!readManifest(entry.absoluteFilePath(), addon, error) || addon.id != entry.fileName()) {
            qCWarning(lcAddons) << "Ignoring invalid add-on folder" << entry.fileName() << error;
            continue;
        }
        addon.enabled = m_store->value(enabledKey(addon.id), true).toBool();
        m_installed.insert(addon.id, addon);
    }
    if (!m_activeMiniPlayerId.isEmpty()) {
        const auto active = m_installed.constFind(m_activeMiniPlayerId);
        if (active == m_installed.cend() || !active->enabled || !hasSlot(*active, QStringLiteral("miniPlayer"))) {
            closeMiniPlayer();
        }
    }
    emit addonsChanged();
}

} // namespace swiftify
