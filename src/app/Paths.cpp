#include "app/Paths.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>

namespace scarlett::paths {

namespace {

QString ensured(const QString &path)
{
    QDir().mkpath(path);
    return path;
}

bool mergeDirectory(const QString &source, const QString &destination)
{
    if (!QDir().mkpath(destination)) return false;
    bool ok = true;
    const QDir sourceDir(source);
    const QFileInfoList entries = sourceDir.entryInfoList(QDir::NoDotAndDotDot | QDir::AllEntries);
    for (const QFileInfo &entry : entries) {
        const QString target = destination + QLatin1Char('/') + entry.fileName();
        if (entry.isDir() && !entry.isSymLink()) {
            if (!QFileInfo::exists(target)) {
                if (!QDir().rename(entry.absoluteFilePath(), target)) ok = false;
            } else if (QFileInfo(target).isDir()) {
                if (!mergeDirectory(entry.absoluteFilePath(), target)) ok = false;
            }
        } else if (!QFileInfo::exists(target)
                   && !QFile::rename(entry.absoluteFilePath(), target)) {
            ok = false;
        }
    }
    if (ok) QDir().rmdir(source);
    return ok;
}

QString appDirectory(QStandardPaths::StandardLocation location)
{
    const QString base = QStandardPaths::writableLocation(location);
    const QString current = base + QStringLiteral("/Scarlett");
    const QString legacy = base + QStringLiteral("/Swiftify");
    if (!QFileInfo::exists(current) && QFileInfo::exists(legacy)) {
        QDir().rename(legacy, current);
    } else if (QFileInfo::exists(current) && QFileInfo::exists(legacy)
               && !mergeDirectory(legacy, current)) {
        return ensured(legacy);
    }
    return ensured(QFileInfo::exists(current) ? current : legacy);
}

} // namespace

QString dataDirectory()
{
    return appDirectory(QStandardPaths::GenericDataLocation);
}

QString cacheDirectory()
{
    return appDirectory(QStandardPaths::GenericCacheLocation);
}

} // namespace scarlett::paths
