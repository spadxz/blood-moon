#pragma once

#include <QHash>
#include <QList>
#include <QObject>
#include <QSettings>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

#include <memory>

class QQmlEngine;
class QJSEngine;

namespace swiftify {

/// Installs and discovers user-authored QML add-ons. Add-ons are ordinary
/// trusted QML components; the package format is versioned independently of
/// the app so compatible add-ons survive app updates.
class AddonManager : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(Addons)
    QML_SINGLETON

    Q_PROPERTY(QVariantList installedAddons READ installedAddons NOTIFY addonsChanged FINAL)
    Q_PROPERTY(QVariantList availableAddons READ availableAddons NOTIFY addonsChanged FINAL)
    Q_PROPERTY(QString installDirectory READ installDirectory CONSTANT FINAL)
    Q_PROPERTY(QString activeMiniPlayerId READ activeMiniPlayerId NOTIFY miniPlayerChanged FINAL)

public:
    static constexpr int kApiVersion = 1;

    explicit AddonManager(QObject *parent);
    AddonManager(const QString &installDirectory, const QString &settingsFile, QObject *parent = nullptr);
    ~AddonManager() override;
    static AddonManager *create(QQmlEngine *, QJSEngine *);

    QVariantList installedAddons() const;
    QVariantList availableAddons() const;
    QString installDirectory() const { return m_installDirectory; }
    QString activeMiniPlayerId() const { return m_activeMiniPlayerId; }
    Q_INVOKABLE QVariantMap addon(const QString &id) const;

    /// Adds an app-bundled package to the user's add-on directory.
    Q_INVOKABLE QString installBundled(const QString &id);
    /// Adds an extracted package folder selected by the user.
    Q_INVOKABLE QString installFromFolder(const QUrl &folderUrl);
    Q_INVOKABLE void setEnabled(const QString &id, bool enabled);
    Q_INVOKABLE QString remove(const QString &id);
    Q_INVOKABLE bool openMiniPlayer(const QString &id);
    Q_INVOKABLE void closeMiniPlayer();
    /// Components exposed at a QML extension point, such as "miniPlayer".
    Q_INVOKABLE QVariantList enabledForSlot(const QString &slot) const;

signals:
    void addonsChanged();
    void miniPlayerChanged();

private:
    struct Extension {
        QString slot;
        QString entryPoint;
    };

    struct Addon {
        QString id;
        QString name;
        QString version;
        QString description;
        QStringList requirements;
        QList<Extension> extensions;
        bool enabled = true;
        bool bundled = false;
    };

    bool readManifest(const QString &directory, Addon &addon, QString &error) const;
    QString installPackage(const QString &source, bool bundled);
    bool copyPackage(const QString &source, const QString &destination, QString &error) const;
    QVariantMap asVariant(const Addon &addon) const;
    void reload();
    QString bundledDirectory(const QString &id) const;
    QString enabledKey(const QString &id) const;
    bool hasSlot(const Addon &addon, const QString &slot) const;

    static AddonManager *s_instance;
    QString m_installDirectory;
    QString m_activeMiniPlayerId;
    std::unique_ptr<QSettings> m_store;
    QHash<QString, Addon> m_installed;
};

} // namespace swiftify
