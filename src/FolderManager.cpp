#include "FolderManager.h"

#include "FolderData.h"
#include "IconProvider.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QUuid>
#include <QSaveFile>
#include <QJsonParseError>
#include <QRegularExpression>
#include <utility>
#include <QTimer>
#include <QUrl>
#include <QSet>

namespace {
QStringList cachedIconsFromFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    QStringList icons;
    for (const QJsonValue &value : document.array()) {
        const QString icon = value.toObject().value(QStringLiteral("icon")).toString();
        if (!icon.isEmpty())
            icons.append(icon);
    }
    return icons;
}

QStringList itemPathsFromFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    QStringList paths;
    for (const QJsonValue &value : document.array()) {
        const QString itemPath = value.toObject().value(QStringLiteral("path")).toString();
        if (!itemPath.isEmpty())
            paths.append(itemPath);
    }
    return paths;
}

bool cachedIconIsReferenced(const QString &icon, const QString &foldersPath)
{
    const QFileInfoList files = QDir(foldersPath).entryInfoList(
        {QStringLiteral("*.json")}, QDir::Files | QDir::Readable);
    for (const QFileInfo &file : files) {
        if (cachedIconsFromFile(file.absoluteFilePath()).contains(icon))
            return true;
    }
    return false;
}

bool itemPathIsReferenced(const QString &itemPath, const QString &foldersPath)
{
    const QFileInfoList files = QDir(foldersPath).entryInfoList(
        {QStringLiteral("*.json")}, QDir::Files | QDir::Readable);
    for (const QFileInfo &file : files) {
        for (const QString &candidate : itemPathsFromFile(file.absoluteFilePath())) {
            if (QDir::cleanPath(candidate).compare(QDir::cleanPath(itemPath),
                                                    Qt::CaseInsensitive) == 0)
                return true;
        }
    }
    return false;
}
}

FolderManager::FolderManager(QObject *parent)
    : QAbstractListModel(parent)
{
    loadDefaults();
    m_defaultFolder = new FolderData(QStringLiteral("新建文件夹默认设置"),
                                     QStringLiteral("__folder_defaults__"), this);
    applyDefaultsToFolder(m_defaultFolder);
    m_defaultsSaveTimer = new QTimer(this);
    m_defaultsSaveTimer->setSingleShot(true);
    m_defaultsSaveTimer->setInterval(250);
    connect(m_defaultsSaveTimer, &QTimer::timeout, this, [this] { saveDefaults(); });
    connect(m_defaultFolder, &FolderData::appearanceChanged,
            this, [this] {
        syncDefaultMembers();
        m_defaultsDirty = true;
        m_defaultsSaveTimer->start();
        emit defaultSettingsChanged();
    });
    connect(m_defaultFolder, &FolderData::interactionChanged,
            this, [this] {
        syncDefaultMembers();
        m_defaultsDirty = true;
        m_defaultsSaveTimer->start();
        emit defaultSettingsChanged();
    });
    load();
}

FolderManager::~FolderManager()
{
    if (m_defaultsDirty)
        saveDefaults();
}

QObject *FolderManager::defaultFolderData() const
{
    return m_defaultFolder;
}

void FolderManager::syncDefaultMembers()
{
    if (!m_defaultFolder)
        return;
    m_defaultGridColumns = m_defaultFolder->gridColumns();
    m_defaultGridRows = m_defaultFolder->gridRows();
    m_defaultIconSize = m_defaultFolder->iconSize();
    m_defaultIconSpacing = m_defaultFolder->iconSpacing();
    m_defaultEdgePadding = m_defaultFolder->edgePadding();
    m_defaultOverflowMode = m_defaultFolder->overflowMode();
    m_defaultFrostedGlass = m_defaultFolder->frostedGlass();
}

void FolderManager::cleanupUnusedCovers() const
{
    QSet<QString> usedPaths;
    const auto rememberCover = [&usedPaths](const QString &cover) {
        const QUrl url(cover);
        if (url.isLocalFile())
            usedPaths.insert(QDir::cleanPath(url.toLocalFile()).toLower());
    };
    rememberCover(m_defaultFolder ? m_defaultFolder->overflowCover() : QString());
    for (const FolderData *folder : m_folders)
        if (folder)
            rememberCover(folder->overflowCover());

    QDir dataDirectory = QFileInfo(configPath()).dir();
    dataDirectory.cdUp();
    QDir coverDirectory(dataDirectory.filePath(QStringLiteral("covers")));
    const QFileInfoList covers = coverDirectory.entryInfoList(
        {QStringLiteral("cover_*.png")}, QDir::Files);
    for (const QFileInfo &cover : covers) {
        if (!usedPaths.contains(QDir::cleanPath(cover.absoluteFilePath()).toLower()))
            QFile::remove(cover.absoluteFilePath());
    }
}

int FolderManager::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_folders.size(); }

QVariant FolderManager::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_folders.size() || role != FolderRole)
        return {};
    return QVariant::fromValue(static_cast<QObject *>(m_folders.at(index.row())));
}

QHash<int, QByteArray> FolderManager::roleNames() const { return {{FolderRole, "folderData"}}; }

QString FolderManager::configPath() const
{

    QString dir = qEnvironmentVariable("DESK_FOLDER_DATA_DIR");
    if (dir.isEmpty())
        dir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);

    const QString configDir = QDir(dir).filePath(QStringLiteral("config"));
    QDir().mkpath(configDir);
    const QString path = QDir(configDir).filePath(QStringLiteral("folders.json"));
    const QString legacyPath = QDir(dir).filePath(QStringLiteral("folders_config.json"));
    if (!QFile::exists(path) && QFile::exists(legacyPath)) {
        if (!QFile::rename(legacyPath, path))
            QFile::copy(legacyPath, path);
    }
    return path;
}

QString FolderManager::defaultsPath() const
{
    const QString path = QFileInfo(configPath()).dir().filePath(QStringLiteral("defaults.json"));
    QDir rootDirectory = QFileInfo(configPath()).dir();
    rootDirectory.cdUp();
    const QString legacyPath = rootDirectory.filePath(QStringLiteral("folder_defaults.json"));
    if (!QFile::exists(path) && QFile::exists(legacyPath)) {
        if (!QFile::rename(legacyPath, path))
            QFile::copy(legacyPath, path);
    }
    return path;
}

void FolderManager::loadDefaults()
{
    QFile file(defaultsPath());
    if (!file.open(QIODevice::ReadOnly))
        return;
    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        qWarning() << "Invalid default folder configuration, preserving file:"
                   << file.fileName() << error.errorString();
        QFile::copy(file.fileName(), file.fileName() + QStringLiteral(".corrupt"));
        return;
    }
    const QJsonObject object = document.object();
    m_defaultGridColumns = qBound(1, object.value("gridColumns").toInt(3), 12);
    m_defaultGridRows = qBound(1, object.value("gridRows").toInt(2), 12);
    m_defaultIconSize = qBound(32, object.value("iconSize").toInt(64), 96);
    m_defaultIconSpacing = qBound(24, object.value("iconSpacing").toInt(36), 80);
    m_defaultEdgePadding = qBound(0, object.value("edgePadding").toInt(20), 80);
    m_defaultOverflowMode = object.value("overflowMode").toBool(false);
    m_defaultFrostedGlass = object.value("frostedGlass").toBool(false);
}

bool FolderManager::saveDefaults()
{
    if (!m_defaultsDirty)
        return true;
    QJsonObject object;
    const FolderData *folder = m_defaultFolder;
    object["gridColumns"] = folder ? folder->gridColumns() : m_defaultGridColumns;
    object["gridRows"] = folder ? folder->gridRows() : m_defaultGridRows;
    object["iconSize"] = folder ? folder->iconSize() : m_defaultIconSize;
    object["iconSpacing"] = folder ? folder->iconSpacing() : m_defaultIconSpacing;
    object["edgePadding"] = folder ? folder->edgePadding() : m_defaultEdgePadding;
    object["overflowMode"] = folder ? folder->overflowMode() : m_defaultOverflowMode;
    object["frostedGlass"] = folder ? folder->frostedGlass() : m_defaultFrostedGlass;
    if (folder) {
        object["cornerRadius"] = folder->cornerRadius();
        object["backgroundStyle"] = folder->backgroundStyle();
        object["backgroundOpacity"] = folder->backgroundOpacity();
        object["showFolderName"] = folder->showFolderName();
        object["showIconNames"] = folder->showIconNames();
        object["showIconBorder"] = folder->showIconBorder();
        object["iconTone"] = folder->iconTone();
        object["allowIconGaps"] = folder->allowIconGaps();
        object["lockPosition"] = folder->lockPosition();
        object["doubleClickToLaunch"] = folder->doubleClickToLaunch();
        object["borderStyle"] = folder->borderStyle();
        object["expansionDirection"] = folder->expansionDirection();
        object["overflowCover"] = folder->overflowCover();
    }
    QSaveFile file(defaultsPath());
    if (!file.open(QIODevice::WriteOnly)) {
        emit persistenceError(tr("无法保存默认文件夹设置：%1").arg(file.errorString()));
        return false;
    }
    if (file.write(QJsonDocument(object).toJson(QJsonDocument::Indented)) < 0
        || !file.commit()) {
        emit persistenceError(tr("无法保存默认文件夹设置：%1").arg(file.errorString()));
        return false;
    }
    m_defaultsDirty = false;
    cleanupUnusedCovers();
    return true;
}

void FolderManager::applyDefaultsToFolder(FolderData *folder) const
{
    if (!folder)
        return;
    if (m_defaultFolder && folder != m_defaultFolder) {
        const FolderData *defaults = m_defaultFolder;
        folder->beginRestore();
        folder->setOverflowMode(defaults->overflowMode());
        folder->setGridColumns(defaults->gridColumns());
        folder->setGridRows(defaults->gridRows());
        folder->setIconSize(defaults->iconSize());
        folder->setIconSpacing(defaults->iconSpacing());
        folder->setEdgePadding(defaults->edgePadding());
        folder->setFrostedGlass(defaults->frostedGlass());
        folder->setCornerRadius(defaults->cornerRadius());
        folder->setBackgroundStyle(defaults->backgroundStyle());
        folder->setBackgroundOpacity(defaults->backgroundOpacity());
        folder->setShowFolderName(defaults->showFolderName());
        folder->setShowIconNames(defaults->showIconNames());
        folder->setShowIconBorder(defaults->showIconBorder());
        folder->setIconTone(defaults->iconTone());
        folder->setAllowIconGaps(defaults->allowIconGaps());
        folder->setLockPosition(defaults->lockPosition());
        folder->setDoubleClickToLaunch(defaults->doubleClickToLaunch());
        folder->setBorderStyle(defaults->borderStyle());
        folder->setExpansionDirection(defaults->expansionDirection());
        folder->setOverflowCover(defaults->overflowCover());
        folder->endRestore();
        return;
    }
    QFile file(defaultsPath());
    QJsonObject object;
    if (file.open(QIODevice::ReadOnly))
        object = QJsonDocument::fromJson(file.readAll()).object();
    folder->beginRestore();
    folder->setOverflowMode(object.value("overflowMode").toBool(m_defaultOverflowMode));
    folder->setGridColumns(object.value("gridColumns").toInt(m_defaultGridColumns));
    folder->setGridRows(object.value("gridRows").toInt(m_defaultGridRows));
    folder->setIconSize(object.value("iconSize").toInt(m_defaultIconSize));
    folder->setIconSpacing(object.value("iconSpacing").toInt(m_defaultIconSpacing));
    folder->setEdgePadding(object.value("edgePadding").toInt(m_defaultEdgePadding));
    folder->setFrostedGlass(object.value("frostedGlass").toBool(m_defaultFrostedGlass));
    folder->setCornerRadius(object.value("cornerRadius").toInt(30));
    folder->setBackgroundStyle(object.value("backgroundStyle").toString("black"));
    folder->setBackgroundOpacity(object.value("backgroundOpacity").toDouble(0.8));
    folder->setShowFolderName(object.value("showFolderName").toBool(true));
    folder->setShowIconNames(object.value("showIconNames").toBool(true));
    folder->setShowIconBorder(object.value("showIconBorder").toBool(false));
    folder->setIconTone(object.value("iconTone").toString("original"));
    folder->setAllowIconGaps(object.value("allowIconGaps").toBool(true));
    folder->setLockPosition(object.value("lockPosition").toBool(false));
    folder->setDoubleClickToLaunch(object.value("doubleClickToLaunch").toBool(false));
    folder->setBorderStyle(object.value("borderStyle").toString("subtle"));
    folder->setExpansionDirection(object.value("expansionDirection").toString("down"));
    folder->setOverflowCover(object.value("overflowCover").toString());
    folder->endRestore();
}

void FolderManager::trackFolder(FolderData *folder)
{
    if (!folder)
        return;
    connect(folder, &FolderData::persistenceError,
            this, &FolderManager::persistenceError);
    const auto markDirty = [this] { m_dirty = true; };
    connect(folder, &FolderData::windowPositionChanged, this, markDirty);
    connect(folder, &FolderData::appearanceChanged, this, markDirty);
    connect(folder, &FolderData::interactionChanged, this, markDirty);
}

#define DEFINE_DEFAULT_SETTER(Name, Member, Min, Max) \
void FolderManager::setDefault##Name(int value) { \
    value = qBound(Min, value, Max); \
    if (Member == value) return; \
    Member = value; \
    if (m_defaultFolder) m_defaultFolder->set##Name(value); \
    else { saveDefaults(); emit defaultSettingsChanged(); } \
}
DEFINE_DEFAULT_SETTER(IconSize, m_defaultIconSize, 32, 96)
DEFINE_DEFAULT_SETTER(IconSpacing, m_defaultIconSpacing, 24, 80)
DEFINE_DEFAULT_SETTER(EdgePadding, m_defaultEdgePadding, 0, 80)
#undef DEFINE_DEFAULT_SETTER

void FolderManager::setDefaultGridColumns(int value)
{
    value = qBound(1, value, 12);
    if (m_defaultGridColumns == value) return;
    m_defaultGridColumns = value;
    if (m_defaultFolder) m_defaultFolder->setGridColumns(value);
    else { saveDefaults(); emit defaultSettingsChanged(); }
}

void FolderManager::setDefaultGridRows(int value)
{
    value = qBound(1, value, 12);
    if (m_defaultGridRows == value) return;
    m_defaultGridRows = value;
    if (m_defaultFolder) m_defaultFolder->setGridRows(value);
    else { saveDefaults(); emit defaultSettingsChanged(); }
}

void FolderManager::setDefaultOverflowMode(bool value)
{
    if (m_defaultOverflowMode == value) return;
    m_defaultOverflowMode = value;
    if (m_defaultFolder) m_defaultFolder->setOverflowMode(value);
    else { saveDefaults(); emit defaultSettingsChanged(); }
}

void FolderManager::setDefaultFrostedGlass(bool value)
{
    if (m_defaultFrostedGlass == value) return;
    m_defaultFrostedGlass = value;
    if (m_defaultFolder) m_defaultFolder->setFrostedGlass(value);
    else { saveDefaults(); emit defaultSettingsChanged(); }
}

void FolderManager::createFolder(
    QString name)
{

    name = name.trimmed();
    if (name.isEmpty() || name.size() > 80 || name.contains(QRegularExpression(QStringLiteral("[\\x00-\\x1f]"))))
        return;
    for (const FolderData *folder : std::as_const(m_folders))
        if (folder->name().compare(name, Qt::CaseInsensitive) == 0)
            return;

    FolderData *folder =
        new FolderData(
            name,
            this);
    applyDefaultsToFolder(folder);
    trackFolder(folder);

    beginInsertRows({}, m_folders.size(), m_folders.size());
    m_folders.append(folder);
    endInsertRows();

    const bool wasDirty = m_dirty;
    m_dirty = true;
    if (!save()) {
        beginRemoveRows({}, m_folders.size() - 1, m_folders.size() - 1);
        m_folders.removeLast();
        endRemoveRows();
        folder->deleteLater();
        m_dirty = wasDirty;
        return;
    }

    emit foldersChanged();
}

bool FolderManager::renameFolder(const QString &folderId, QString name)
{
    name = name.trimmed();
    if (folderId.isEmpty() || name.isEmpty() || name.size() > 80
        || name.contains(QRegularExpression(QStringLiteral("[\\x00-\\x1f]"))))
        return false;

    FolderData *target = nullptr;
    int targetIndex = -1;
    for (int i = 0; i < m_folders.size(); ++i) {
        FolderData *folder = m_folders.at(i);
        if (folder && folder->folderId() == folderId) {
            target = folder;
            targetIndex = i;
        } else if (folder && folder->name().compare(name, Qt::CaseInsensitive) == 0) {
            return false;
        }
    }
    if (!target)
        return false;
    if (target->name() == name)
        return true;

    const QString oldName = target->name();
    const bool wasDirty = m_dirty;
    target->setName(name);
    m_dirty = true;
    if (!save()) {
        target->setName(oldName);
        m_dirty = wasDirty;
        return false;
    }

    emit dataChanged(index(targetIndex, 0), index(targetIndex, 0), {FolderRole});
    return true;
}

void FolderManager::removeFolder(
    int index)
{

    if (
        index < 0 ||
        index >= m_folders.size())
    {
        return;
    }

    FolderData *folder = m_folders[index];
    const bool wasDirty = m_dirty;
    beginRemoveRows({}, index, index);
    FolderData *obj = m_folders.takeAt(index);
    endRemoveRows();

    m_dirty = true;
    if (!save()) {
        beginInsertRows({}, index, index);
        m_folders.insert(index, obj);
        endInsertRows();
        m_dirty = wasDirty;
        emit foldersChanged();
        return;
    }

    // Only delete the instance data after the new folder list is durably
    // committed. A failed metadata save must not orphan the folder.
    if (folder) {
        QString dir = qEnvironmentVariable("DESK_FOLDER_DATA_DIR");
        if (dir.isEmpty())
            dir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        const QString dataFile = QDir(dir).filePath(
            QStringLiteral("folders/%1.json").arg(folder->folderId()));
        const QStringList cachedIcons = cachedIconsFromFile(dataFile);
        const QStringList itemPaths = itemPathsFromFile(dataFile);
        QFile::remove(dataFile);
        QFile::remove(QDir(dir).filePath(folder->folderId() + QStringLiteral(".json")));
        QFile::remove(QDir(dir).filePath(folder->name() + QStringLiteral(".json")));
        const QString foldersPath = QFileInfo(dataFile).absolutePath();
        for (const QString &icon : cachedIcons) {
            if (!cachedIconIsReferenced(icon, foldersPath))
                IconProvider::removeCachedIcon(icon);
        }
        const QString shortcutRoot = QDir::cleanPath(
            QDir(dir).filePath(QStringLiteral("shortcuts"))) + QDir::separator();
        for (const QString &itemPath : itemPaths) {
            const QString absolutePath = QDir::cleanPath(QFileInfo(itemPath).absoluteFilePath());
            if (absolutePath.startsWith(shortcutRoot, Qt::CaseInsensitive)
                && QFileInfo(absolutePath).suffix().compare(QStringLiteral("lnk"), Qt::CaseInsensitive) == 0
                && !itemPathIsReferenced(absolutePath, foldersPath)) {
                QFile::remove(absolutePath);
            }
        }
    }

    obj->deleteLater();

    cleanupUnusedCovers();
    emit foldersChanged();
}

int FolderManager::folderCount()
{

    return m_folders.size();
}

QObject *FolderManager::folderAt(
    int index)
{

    if (
        index < 0 ||
        index >= m_folders.size())
    {
        return nullptr;
    }

    return m_folders[index];
}

void FolderManager::load()
{
    m_dirty = false;

    QFile file(configPath());

    if (!file.exists())
    {
        qDebug()
            << "[FolderManager] load: 配置不存在, 跳过";
        return;
    }

    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray data =
        file.readAll();

    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);
    if (error.error != QJsonParseError::NoError || !doc.isArray()) {
        qWarning() << "Invalid folder configuration, preserving file:" << configPath() << error.errorString();
        QFile::copy(configPath(), configPath() + ".corrupt");
        return;
    }

    QJsonArray array =
        doc.array();

    bool migratedData = false;

    beginResetModel();
    qDeleteAll(m_folders);
    m_folders.clear();
    for (auto value : array)
    {

        QJsonObject obj =
            value.toObject();

        QString name =
            obj["name"].toString();

        if (name.isEmpty())
            continue;

        // 读取 folderId (旧版配置可能没有, 则生成新的)
        QString folderId =
            obj["id"].toString();

        if (folderId.isEmpty())
        {
            folderId =
                QUuid::createUuid()
                    .toString(
                        QUuid::WithoutBraces);
            migratedData = true;
        }

        int wx = -1;
        int wy = -1;

        // 恢复窗口位置
        if (obj.contains("windowX") &&
            obj.contains("windowY"))
        {
            wx = obj["windowX"].toInt();
            wy = obj["windowY"].toInt();
        }

        FolderData *folder =
            new FolderData(
                name,
                folderId,
                this);
        folder->beginRestore();
        folder->setWindowPosition(
            wx,
            wy);
        folder->setCornerRadius(obj.value("cornerRadius").toInt(30));
        folder->setBackgroundStyle(obj.value("backgroundStyle").toString("black"));
        folder->setBackgroundOpacity(obj.value("backgroundOpacity").toDouble(0.8));
        folder->setIconSize(obj.value("iconSize").toInt(64));
        folder->setIconSpacing(obj.value("iconSpacing").toInt(36));
        folder->setEdgePadding(obj.value("edgePadding").toInt(20));
        // Restore overflow mode before grid dimensions so a compact grid is
        // not enlarged to fit all items during startup.
        folder->setOverflowMode(obj.value("overflowMode").toBool(false));
        folder->setExpansionDirection(obj.value("expansionDirection").toString("down"));
        QString overflowCover = obj.value("overflowCover").toString();
        overflowCover.replace(QStringLiteral("assets/covers/aurora.svg"),
                              QStringLiteral("assets/covers/arrows.svg"));
        overflowCover.replace(QStringLiteral("assets/covers/sunset.svg"),
                              QStringLiteral("assets/covers/multitask.svg"));
        overflowCover.replace(QStringLiteral("assets/covers/mint.svg"),
                              QStringLiteral("assets/covers/projects.svg"));
        if (overflowCover != obj.value("overflowCover").toString())
            migratedData = true;
        folder->setOverflowCover(overflowCover);
        folder->setGridColumns(obj.value("gridColumns").toInt(3));
        folder->setGridRows(obj.value("gridRows").toInt(2));
        folder->setShowFolderName(obj.value("showFolderName").toBool(true));
        folder->setShowIconNames(obj.value("showIconNames").toBool(true));
        folder->setShowIconBorder(obj.contains("showIconBorder")
            ? obj.value("showIconBorder").toBool(false)
            : obj.value("autoFillTransparentIcons").toBool(false));
        folder->setIconTone(obj.value("iconTone").toString("original"));
        folder->setAllowIconGaps(obj.value("allowIconGaps").toBool(true));
        folder->setLockPosition(obj.value("lockPosition").toBool(false));
        folder->setDoubleClickToLaunch(obj.value("doubleClickToLaunch").toBool(false));
        folder->setFrostedGlass(obj.value("frostedGlass").toBool(false));
        folder->setBorderStyle(obj.value("borderStyle").toString("subtle"));
        folder->endRestore();
        trackFolder(folder);

        m_folders.append(folder);
    }

    endResetModel();
    emit foldersChanged();

    // 如果旧版配置缺少 id, 立即保存以固化 UUID
    m_dirty = migratedData;
    if (migratedData)
        save();
}

bool FolderManager::save()
{
    if (m_defaultsDirty && !saveDefaults())
        return false;
    if (!m_dirty)
        return true;

    QJsonArray array;

    for (FolderData *folder : m_folders)
    {
        if (!folder)
            continue;

        QJsonObject json;

        json["name"] =
            folder->name();

        json["id"] =
            folder->folderId();

        json["windowX"] =
            folder->windowX();

        json["windowY"] =
            folder->windowY();
        json["cornerRadius"] = folder->cornerRadius();
        json["backgroundStyle"] = folder->backgroundStyle();
        json["backgroundOpacity"] = folder->backgroundOpacity();
        json["iconSize"] = folder->iconSize();
        json["iconSpacing"] = folder->iconSpacing();
        json["edgePadding"] = folder->edgePadding();
        json["gridColumns"] = folder->gridColumns();
        json["gridRows"] = folder->gridRows();
        json["showFolderName"] = folder->showFolderName();
        json["showIconNames"] = folder->showIconNames();
        json["showIconBorder"] = folder->showIconBorder();
        json["iconTone"] = folder->iconTone();
        json["allowIconGaps"] = folder->allowIconGaps();
        json["lockPosition"] = folder->lockPosition();
        json["doubleClickToLaunch"] = folder->doubleClickToLaunch();
        json["frostedGlass"] = folder->frostedGlass();
        json["borderStyle"] = folder->borderStyle();
        json["overflowMode"] = folder->overflowMode();
        json["expansionDirection"] = folder->expansionDirection();
        json["overflowCover"] = folder->overflowCover();

        array.append(json);
    }

    QJsonDocument doc(array);

    QSaveFile file(configPath());

    if (file.open(QIODevice::WriteOnly))
    {

        if (file.write(doc.toJson()) < 0 || !file.commit()) {
            qWarning() << "Failed to save folder configuration:" << file.errorString();
            emit persistenceError(tr("无法保存文件夹配置：%1").arg(file.errorString()));
            return false;
        }
        m_dirty = false;
        cleanupUnusedCovers();
        return true;
    }
    qWarning() << "Failed to open folder configuration for writing:" << file.errorString();
    emit persistenceError(tr("无法写入文件夹配置：%1").arg(file.errorString()));
    return false;
}
