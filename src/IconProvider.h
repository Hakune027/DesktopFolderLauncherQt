#ifndef ICONPROVIDER_H
#define ICONPROVIDER_H

#include <QString>

class IconProvider
{

public:
    static QString getIcon(
        const QString &filePath);
    static bool removeCachedIcon(const QString &iconUrl);
};

#endif
