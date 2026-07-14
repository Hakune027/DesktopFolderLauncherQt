#include <QtTest>
#include <QStandardPaths>
#include "FolderManager.h"
#include "FolderData.h"

class ModelTests : public QObject
{
    Q_OBJECT
private slots:
    void initTestCase()
    {
        QStandardPaths::setTestModeEnabled(true);
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
};

QTEST_APPLESS_MAIN(ModelTests)
#include "model_tests.moc"
