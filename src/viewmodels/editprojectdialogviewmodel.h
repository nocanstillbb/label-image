#ifndef EDITPROJECTDIALOGVIEWMODEL_H
#define EDITPROJECTDIALOGVIEWMODEL_H

#include <QObject>
#include <models/app_config.h>

class editProjectDialogViewmodel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(prismModelProxy<MLProject>* editModel READ editModel WRITE setEditModel NOTIFY editModelChanged)
  private:
    prismModelProxy<MLProject>* m_editModel = nullptr;
    prismModelProxy<MLProject>* m_model = nullptr;

  public:
    explicit editProjectDialogViewmodel(QObject* parent = nullptr, prismModelProxy<MLProject>* model = nullptr);

    prismModelProxy<MLProject>* editModel() const;
    void setEditModel(prismModelProxy<MLProject>* newEditModel);

  public slots:
    void save();

  signals:
    void editModelChanged();
};

#endif // EDITPROJECTDIALOGVIEWMODEL_H
