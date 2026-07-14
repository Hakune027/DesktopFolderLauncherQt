#ifndef APPITEM_H
#define APPITEM_H

#include <QObject>

class AppItem : public QObject
{

    Q_OBJECT

    Q_PROPERTY(
        QString name
            READ name
                CONSTANT)

    Q_PROPERTY(
        QString path
            READ path
                CONSTANT)

    Q_PROPERTY(
        QString icon
            READ icon
                CONSTANT)

    // 新增位置属性

    Q_PROPERTY(
        int x
            READ x
                WRITE setX
                    NOTIFY positionChanged)

    Q_PROPERTY(
        int y
            READ y
                WRITE setY
                    NOTIFY positionChanged)

public:
    explicit AppItem(
        QString name,
        QString path,
        QString icon,
        QObject *parent = nullptr);

    QString name() const;

    QString path() const;

    QString icon() const;

    int x() const;

    int y() const;

    void setX(
        int value);

    void setY(
        int value);

    Q_INVOKABLE
    void open();

signals:

    void positionChanged();

private:
    QString m_name;

    QString m_path;

    QString m_icon;

    int m_x = 0;

    int m_y = 0;
};

#endif
