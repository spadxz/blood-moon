#include "ViewRig.h"
#include "app/Fonts.h"
#include <QQmlComponent>
#include <QLineF>
#include <QtQml/qqmlextensionplugin.h>
Q_IMPORT_QML_PLUGIN(ScarlettPlugin)
using namespace scarlett;
class MenuTest : public QObject {
    Q_OBJECT
private slots:
    void initTestCase() { fonts::loadIconFont(); fonts::loadInterfaceFont(); }
    void menuPositionStaysStableDuringEntry_data() {
        QTest::addColumn<int>("windowHeight");
        QTest::newRow("short-window") << 400;
        QTest::newRow("full-height-window") << 780;
    }
    void menuPositionStaysStableDuringEntry() {
        QFETCH(int, windowHeight);
        testing::ViewRig rig;
        rig.window->resize(1280, windowHeight);
        QQmlComponent component(&rig.engine);
        component.setData("import QtQuick\nimport Scarlett\nItem { width: 1280; height: 400; property alias loader: loader; ToolbarButton { id: anchor; x: 1220; y: 24; size: 40; effect: ToolbarButton.Spin; onClicked: loader.popupAt(anchor, 0, height) } function openMenu() { anchor.clicked() } MenuLoader { id: loader; sourceComponent: PlaybackMenu {} } }", QUrl());
        std::unique_ptr<QObject> root(component.create());
        QVERIFY2(root, qPrintable(component.errorString()));
        qobject_cast<QQuickItem *>(root.get())->setParentItem(rig.window->contentItem());
        rig.window->show();
        for (int opening = 0; opening < 3; ++opening) {
            QVERIFY(QMetaObject::invokeMethod(root.get(), "openMenu"));
            auto *loader = root->property("loader").value<QObject *>();
            auto *menu = loader->property("item").value<QObject *>();
            QVERIFY(menu);
            QVERIFY2(qFuzzyCompare(menu->property("scale").toReal(), 1.0), "Popup scales its own bounds while opening");
            auto *content = menu->property("contentItem").value<QQuickItem *>();
            QVERIFY(content);
            rig.render();
            const QPointF initialPosition = content->mapToScene(QPointF(0, 0));
            const qreal initialX = menu->property("x").toReal();
            const qreal initialY = menu->property("y").toReal();
            for (int tick = 0; tick < 100; ++tick) {
                QTest::qWait(5);
                rig.render();
                QVERIFY2(QLineF(initialPosition, content->mapToScene(QPointF(0, 0))).length() < 1, "Menu follows its animated anchor across the window");
                QVERIFY2(qAbs(menu->property("x").toReal() - initialX) < 1, "Menu moves horizontally while entering");
                QVERIFY2(qAbs(menu->property("y").toReal() - initialY) < 1, "Menu jumps vertically while entering");
            }
            QVERIFY(menu->property("opened").toBool());
            const QString preview = qEnvironmentVariable("SCARLETT_MENU_PREVIEW");
            if (!preview.isEmpty()) QVERIFY(rig.render().save(preview));
            QVERIFY(QMetaObject::invokeMethod(root.get(), "openMenu"));
            QTRY_VERIFY(!menu->property("visible").toBool());
            QVERIFY(QMetaObject::invokeMethod(root.get(), "openMenu"));
            QTRY_VERIFY(menu->property("opened").toBool());
            QTest::mouseClick(rig.window.get(), Qt::LeftButton, Qt::NoModifier, QPoint(100, 200));
            QTRY_VERIFY(!menu->property("visible").toBool());
        }
    }
};
QTEST_MAIN(MenuTest)
#include "tst_menus.moc"
