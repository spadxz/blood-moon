#include "app/Settings.h"
#include "app/Translations.h"

#include <QCoreApplication>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QTemporaryDir>
#include <QTest>

using namespace scarlett;

class TranslationsTest : public QObject {
    Q_OBJECT
private slots:
    void catalogIsEmbeddedAndValid()
    {
        QFile file(QStringLiteral(":/translations/ru.json"));
        QVERIFY(file.open(QIODevice::ReadOnly));
        QJsonParseError error;
        const auto document = QJsonDocument::fromJson(file.readAll(), &error);
        QCOMPARE(error.error, QJsonParseError::NoError);
        QVERIFY(document.object().size() > 300);
        const auto catalog = document.object();
        for (auto it = catalog.begin(); it != catalog.end(); ++it) {
            if (it.value().isArray()) {
                QCOMPARE(it.value().toArray().size(), 3);
                for (const auto &value : it.value().toArray()) QVERIFY(!value.toString().isEmpty());
            } else {
                QVERIFY2(!it.value().toString().isEmpty(), qPrintable(it.key()));
            }
        }
    }

    void switchesLiveAndFallsBackToEnglish()
    {
        QTemporaryDir directory;
        Settings settings(directory.filePath(QStringLiteral("settings.ini")));
        settings.setLanguage(QStringLiteral("en"));
        Translations translations(&settings);
        QQmlEngine engine;
        connect(&translations, &Translations::languageChanged, &engine, &QQmlEngine::retranslate);
        QQmlComponent component(&engine);
        component.setData("import QtQml\nQtObject { property string label: qsTr(\"Settings\") }", QUrl());
        std::unique_ptr<QObject> object(component.create());
        QVERIFY2(object, qPrintable(component.errorString()));
        QCOMPARE(object->property("label").toString(), QStringLiteral("Settings"));
        settings.setLanguage(QStringLiteral("ru"));
        QCOMPARE(object->property("label").toString(), QStringLiteral("Настройки"));
        QCOMPARE(QCoreApplication::translate("test", "custom playlist"), QStringLiteral("custom playlist"));
        settings.setLanguage(QStringLiteral("en"));
        QCOMPARE(object->property("label").toString(), QStringLiteral("Settings"));
    }

    void russianPluralForms_data()
    {
        QTest::addColumn<int>("count");
        QTest::addColumn<QString>("expected");
        QTest::newRow("one") << 1 << QStringLiteral("1 трек");
        QTest::newRow("two") << 2 << QStringLiteral("2 трека");
        QTest::newRow("five") << 5 << QStringLiteral("5 треков");
        QTest::newRow("eleven") << 11 << QStringLiteral("11 треков");
        QTest::newRow("fourteen") << 14 << QStringLiteral("14 треков");
        QTest::newRow("twenty-one") << 21 << QStringLiteral("21 трек");
        QTest::newRow("twenty-two") << 22 << QStringLiteral("22 трека");
        QTest::newRow("zero") << 0 << QStringLiteral("0 треков");
    }

    void russianPluralForms()
    {
        QFETCH(int, count);
        QFETCH(QString, expected);
        QTemporaryDir directory;
        Settings settings(directory.filePath(QStringLiteral("settings.ini")));
        settings.setLanguage(QStringLiteral("ru"));
        Translations translations(&settings);
        QCOMPARE(QCoreApplication::translate("Format", "%n songs", nullptr, count), expected);
    }
};

QTEST_GUILESS_MAIN(TranslationsTest)
#include "tst_translations.moc"
