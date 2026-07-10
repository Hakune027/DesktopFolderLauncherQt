#ifndef APPITEM_H
#define APPITEM_H

#include <QObject>

class AppItem : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(QString icon READ icon CONSTANT)

public:
    explicit AppItem(
        QString name,
        QString path,
        QString icon,
        QObject *parent = nullptr);

    QString name() const;

    QString path() const;

    QString icon() const;

    // 新增
    Q_INVOKABLE
    void open();

private:
    QString m_name;

    QString m_path;

    QString m_icon;
};

#endif