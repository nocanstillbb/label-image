#ifndef EDITPROJECTDIALOGVIEWMODEL_H
#define EDITPROJECTDIALOGVIEWMODEL_H

#include <QObject>
#include <QVariant>
#include <models/app_config.h>
#include <viewmodels/mainviewmodel.h>

class editProjectDialogViewmodel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(prismModelProxy<MLProject>* editModel READ editModel WRITE setEditModel NOTIFY editModelChanged)
    Q_PROPERTY(mainViewModel* parentVM READ parentVM WRITE setParentVM NOTIFY parentVMChanged)
  private:
    prismModelProxy<MLProject>* m_editModel = nullptr;
    prismModelProxy<MLProject>* m_model = nullptr;

    mainViewModel* m_parentVM = nullptr;

  public:
    explicit editProjectDialogViewmodel(QObject* parent = nullptr, prismModelProxy<MLProject>* model = nullptr);

    prismModelProxy<MLProject>* editModel() const;
    void setEditModel(prismModelProxy<MLProject>* newEditModel);

    mainViewModel* parentVM() const;
    void setParentVM(mainViewModel* newParentVM);

  public slots:
    void save();

  signals:
    void editModelChanged();
    void parentVMChanged();
};

#endif // EDITPROJECTDIALOGVIEWMODEL_H
