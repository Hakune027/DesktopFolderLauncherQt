#include "FolderManager.h"

#include "FolderData.h"

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

FolderManager::FolderManager(QObject *parent)
    : QAbstractListModel(parent)
{
    loadDefaults();
    m_defaultFolder = new FolderData(QStringLiteral("新建文件夹默认设置"),
                                     QStringLiteral("__folder_defaults__"), this);
    applyDefaultsToFolder(m_defaultFolder);
    connect(m_defaultFolder, &FolderData::appearanceChanged,
            this, [this] { saveDefaults(); emit defaultSettingsChanged(); });
    connect(m_defaultFolder, &FolderData::interactionChanged,
            this, [this] { saveDefaults(); emit defaultSettingsChanged(); });
    load();
}

QObject *FolderManager::defaultFolderData() const
{
    return m_defaultFolder;
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
    const QJsonObject object = QJsonDocument::fromJson(file.readAll()).object();
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
        object["borderStyle"] = folder->borderStyle();
        object["expansionDirection"] = folder->expansionDirection();
        object["overflowCover"] = folder->overflowCover();
    }
    QSaveFile file(defaultsPath());
    if (!file.open(QIODevice::WriteOnly)) {
        emit persistenceError(tr("无法保存默认文件夹设置：%1").arg(file.errorString()));
        return false;
    }
    file.write(QJsonDocument(object).toJson(QJsonDocument::Indented));
    if (!file.commit()) {
        emit persistenceError(tr("无法保存默认文件夹设置：%1").arg(file.errorString()));
        return false;
    }
    return true;
}

void FolderManager::applyDefaultsToFolder(FolderData *folder) const
{
    if (!folder)
        return;
    QFile file(defaultsPath());
    QJsonObject object;
    if (file.open(QIODevice::ReadOnly))
        object = QJsonDocument::fromJson(file.readAll()).object();
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
    folder->setBorderStyle(object.value("borderStyle").toString("subtle"));
    folder->setExpansionDirection(object.value("expansionDirection").toString("down"));
    folder->setOverflowCover(object.value("overflowCover").toString());
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
    connect(folder, &FolderData::persistenceError,
            this, &FolderManager::persistenceError);
    applyDefaultsToFolder(folder);

    beginInsertRows({}, m_folders.size(), m_folders.size());
    m_folders.append(folder);
    endInsertRows();

    if (!save()) {
        beginRemoveRows({}, m_folders.size() - 1, m_folders.size() - 1);
        m_folders.removeLast();
        endRemoveRows();
        folder->deleteLater();
        return;
    }

    emit foldersChanged();
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
    beginRemoveRows({}, index, index);
    FolderData *obj = m_folders.takeAt(index);
    endRemoveRows();

    if (!save()) {
        beginInsertRows({}, index, index);
        m_folders.insert(index, obj);
        endInsertRows();
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
        QFile::remove(dataFile);
        QFile::remove(QDir(dir).filePath(folder->folderId() + QStringLiteral(".json")));
        QFile::remove(QDir(dir).filePath(folder->name() + QStringLiteral(".json")));
    }

    obj->deleteLater();

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

    qDebug()
        << "[FolderManager] load >>>";

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

        qDebug()
            << "  "
            << name
            << folderId
            << "pos:"
            << wx << wy;

        FolderData *folder =
            new FolderData(
                name,
                folderId,
                this);
        connect(folder, &FolderData::persistenceError,
                this, &FolderManager::persistenceError);

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
        folder->setFrostedGlass(obj.value("frostedGlass").toBool(false));
        folder->setBorderStyle(obj.value("borderStyle").toString("subtle"));

        m_folders.append(folder);
    }

    qDebug()
        << "[FolderManager] load <<<";

    endResetModel();
    emit foldersChanged();

    // 如果旧版配置缺少 id, 立即保存以固化 UUID
    save();
}

bool FolderManager::save()
{

    QJsonArray array;

    qDebug()
        << "[FolderManager] save >>>";

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
        json["frostedGlass"] = folder->frostedGlass();
        json["borderStyle"] = folder->borderStyle();
        json["overflowMode"] = folder->overflowMode();
        json["expansionDirection"] = folder->expansionDirection();
        json["overflowCover"] = folder->overflowCover();

        qDebug()
            << "  "
            << folder->name()
            << folder->folderId()
            << "pos:"
            << folder->windowX()
            << folder->windowY();

        array.append(json);
    }

    qDebug()
        << "[FolderManager] save <<<";

    QJsonDocument doc(array);

    QSaveFile file(configPath());

    if (file.open(QIODevice::WriteOnly))
    {

        if (file.write(doc.toJson()) < 0 || !file.commit()) {
            qWarning() << "Failed to save folder configuration:" << file.errorString();
            emit persistenceError(tr("无法保存文件夹配置：%1").arg(file.errorString()));
            return false;
        }
        return true;
    }
    qWarning() << "Failed to open folder configuration for writing:" << file.errorString();
    emit persistenceError(tr("无法写入文件夹配置：%1").arg(file.errorString()));
    return false;
}
