#pragma once

#include <QJsonObject>
#include <QTranslator>

namespace scarlett {

class Settings;

/// Uses Qt's normal qsTr/tr bindings; the small UTF-8 catalog is embedded so
/// building translations doesn't require an additional Linguist installation.
class Translations : public QTranslator {
    Q_OBJECT
public:
    explicit Translations(Settings *settings, QObject *parent = nullptr);
    ~Translations() override;
    QString translate(const char *context, const char *sourceText,
                      const char *disambiguation = nullptr, int n = -1) const override;
    bool isEmpty() const override { return m_catalog.isEmpty(); }

signals:
    void languageChanged();

private:
    void apply();
    Settings *m_settings;
    QJsonObject m_catalog;
    bool m_russian = false;
};

} // namespace scarlett
