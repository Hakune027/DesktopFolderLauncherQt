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

private:
    QString m_dataDir;
};

// FolderManager uses QStandardPaths and therefore requires a QCoreApplication
// with application metadata. APPLESS_MAIN leaves the writable test path empty.
QTEST_GUILESS_MAIN(ModelTests)
#include "model_tests.moc"
