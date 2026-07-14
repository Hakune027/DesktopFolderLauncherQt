#include <QtTest>
#include <QStandardPaths>
#include <QDir>
#include <QUuid>
#include "FolderManager.h"
#include "FolderData.h"

class ModelTests : public QObject
{
    Q_OBJECT
private slots:
    void initTestCase()
    {
        QStandardPaths::setTestModeEnabled(true);
        m_dataDir = QDir::tempPath() + "/DeskFolderTests-"
                    + QUuid::createUuid().toString(QUuid::WithoutBraces);
        QVERIFY(QDir().mkpath(m_dataDir));
        qputenv("DESK_FOLDER_DATA_DIR", m_dataDir.toUtf8());
    }

    void cleanupTestCase()
    {
        qunsetenv("DESK_FOLDER_DATA_DIR");
        QDir(m_dataDir).removeRecursively();
    }

    void folderNamesAreValidatedAndUnique()
    {
        FolderManager manager;
        const int initial = manager.rowCount();
        manager.createFolder("   ");
        QCOMPARE(manager.rowCount(), initial);

        manager.createFolder("Codex Test Folder");
        QCOMPARE(manager.rowCount(), initial + 1);
        manager.createFolder("codex test folder");
        QCOMPARE(manager.rowCount(), initial + 1);
        manager.removeFolder(initial);
        QCOMPARE(manager.rowCount(), initial);
    }

    void modelRoleReturnsFolderObject()
    {
        FolderManager manager;
        manager.createFolder("Role Test Folder");
        const QModelIndex index = manager.index(manager.rowCount() - 1, 0);
        QObject *object = manager.data(index, FolderManager::FolderRole).value<QObject *>();
        QVERIFY(qobject_cast<FolderData *>(object));
        manager.removeFolder(index.row());
    }

    void newFolderUsesSavedDefaults()
    {
        FolderManager manager;
        manager.setDefaultGridColumns(4);
        manager.setDefaultGridRows(3);
        manager.setDefaultIconSize(72);
        manager.setDefaultIconSpacing(44);
        manager.setDefaultEdgePadding(28);
        manager.setDefaultOverflowMode(true);
        manager.setDefaultFrostedGlass(true);
        manager.createFolder("Defaults Test Folder");

        auto *folder = qobject_cast<FolderData *>(manager.folderAt(manager.rowCount() - 1));
        QVERIFY(folder);
        QCOMPARE(folder->gridColumns(), 4);
        QCOMPARE(folder->gridRows(), 3);
        QCOMPARE(folder->iconSize(), 72);
        QCOMPARE(folder->iconSpacing(), 44);
        QCOMPARE(folder->edgePadding(), 28);
        QVERIFY(folder->overflowMode());
        QVERIFY(folder->frostedGlass());
        manager.removeFolder(manager.rowCount() - 1);
    }

    void oneByOneGridIsAllowed()
    {
        FolderManager manager;
        manager.setDefaultGridColumns(1);
        manager.setDefaultGridRows(1);
        manager.createFolder("One Cell Folder");
        auto *folder = qobject_cast<FolderData *>(manager.folderAt(manager.rowCount() - 1));
        QVERIFY(folder);
        QCOMPARE(folder->gridColumns(), 1);
        QCOMPARE(folder->gridRows(), 1);
        manager.removeFolder(manager.rowCount() - 1);
    }

private:
    QString m_dataDir;
};

// FolderManager uses QStandardPaths and therefore requires a QCoreApplication
// with application metadata. APPLESS_MAIN leaves the writable test path empty.
QTEST_GUILESS_MAIN(ModelTests)
#include "model_tests.moc"
