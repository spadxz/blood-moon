#include "addons/AddonManager.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QTemporaryDir>
#include <QTest>

using swiftify::AddonManager;

namespace {

bool writeFile(const QString &path, const QByteArray &contents)
{
    QFile file(path);
    return file.open(QIODevice::WriteOnly) && file.write(contents) == contents.size();
}

QByteArray manifest(const QString &entryPoint = QStringLiteral("Mini.qml"), int apiVersion = 1)
{
    const QJsonObject extension {{QStringLiteral("slot"), QStringLiteral("miniPlayer")},
                                 {QStringLiteral("entryPoint"), entryPoint}};
    const QJsonObject object {{QStringLiteral("apiVersion"), apiVersion},
                              {QStringLiteral("id"), QStringLiteral("test-mini-player")},
                              {QStringLiteral("name"), QStringLiteral("Test Mini Player")},
                              {QStringLiteral("version"), QStringLiteral("1.0.0")},
                              {QStringLiteral("description"), QStringLiteral("Test extension package.")},
                              {QStringLiteral("extensions"), QJsonArray {extension}}};
    return QJsonDocument(object).toJson(QJsonDocument::Compact);
}

} // namespace

class AddonManagerTest : public QObject {
    Q_OBJECT

private slots:
    void installEnableOpenPersistAndRemove()
    {
        QTemporaryDir root;
        QVERIFY(root.isValid());
        const QString package = QDir(root.path()).filePath(QStringLiteral("package"));
        const QString installDirectory = QDir(root.path()).filePath(QStringLiteral("installed"));
        const QString settingsFile = QDir(root.path()).filePath(QStringLiteral("settings.ini"));
        QVERIFY(QDir().mkpath(package));
        QVERIFY(writeFile(QDir(package).filePath(QStringLiteral("manifest.json")), manifest()));
        QVERIFY(writeFile(QDir(package).filePath(QStringLiteral("Mini.qml")), "import QtQuick\nItem {}\n"));

        {
            AddonManager manager(installDirectory, settingsFile);
            QVERIFY(manager.installedAddons().isEmpty());
            const QString message = manager.installFromFolder(QUrl::fromLocalFile(package));
            QVERIFY2(message.startsWith(QStringLiteral("Installed ")), qPrintable(message));
            QCOMPARE(manager.installedAddons().size(), 1);
            const QVariantMap installed = manager.addon(QStringLiteral("test-mini-player"));
            QCOMPARE(installed.value(QStringLiteral("name")).toString(), QStringLiteral("Test Mini Player"));
            QVERIFY(installed.value(QStringLiteral("enabled")).toBool());
            QCOMPARE(manager.enabledForSlot(QStringLiteral("miniPlayer")).size(), 1);
            QVERIFY(manager.openMiniPlayer(QStringLiteral("test-mini-player")));
            QCOMPARE(manager.activeMiniPlayerId(), QStringLiteral("test-mini-player"));

            manager.setEnabled(QStringLiteral("test-mini-player"), false);
            QVERIFY(manager.activeMiniPlayerId().isEmpty());
            QVERIFY(manager.enabledForSlot(QStringLiteral("miniPlayer")).isEmpty());
        }

        {
            AddonManager manager(installDirectory, settingsFile);
            QCOMPARE(manager.installedAddons().size(), 1);
            QVERIFY(!manager.addon(QStringLiteral("test-mini-player")).value(QStringLiteral("enabled")).toBool());
            manager.setEnabled(QStringLiteral("test-mini-player"), true);
            QVERIFY(manager.openMiniPlayer(QStringLiteral("test-mini-player")));
            QVERIFY(manager.remove(QStringLiteral("test-mini-player")).startsWith(QStringLiteral("Removed ")));
            QVERIFY(manager.installedAddons().isEmpty());
            QVERIFY(!QDir(installDirectory).exists(QStringLiteral("test-mini-player")));
        }
    }

    void rejectsTraversalAndApiMismatch()
    {
        QTemporaryDir root;
        QVERIFY(root.isValid());
        const QString package = QDir(root.path()).filePath(QStringLiteral("package"));
        const QString installDirectory = QDir(root.path()).filePath(QStringLiteral("installed"));
        QVERIFY(QDir().mkpath(package));
        QVERIFY(writeFile(QDir(package).filePath(QStringLiteral("manifest.json")), manifest(QStringLiteral("../outside.qml"))));
        QVERIFY(writeFile(QDir(root.path()).filePath(QStringLiteral("outside.qml")), "import QtQuick\nItem {}\n"));

        AddonManager manager(installDirectory, QDir(root.path()).filePath(QStringLiteral("settings.ini")));
        QVERIFY(manager.installFromFolder(QUrl::fromLocalFile(package)).contains(QStringLiteral("relative QML file")));
        QVERIFY(manager.installedAddons().isEmpty());

        QVERIFY(writeFile(QDir(package).filePath(QStringLiteral("manifest.json")), manifest(QStringLiteral("Mini.qml"), 99)));
        QVERIFY(writeFile(QDir(package).filePath(QStringLiteral("Mini.qml")), "import QtQuick\nItem {}\n"));
        QVERIFY(manager.installFromFolder(QUrl::fromLocalFile(package)).contains(QStringLiteral("targets API 99")));
        QVERIFY(manager.installedAddons().isEmpty());
    }
};

QTEST_GUILESS_MAIN(AddonManagerTest)
#include "tst_addons.moc"
