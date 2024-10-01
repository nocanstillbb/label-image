#include "editprojectdialogviewmodel.h"
#include <QDir>
#include <QStandardPaths>
#include <QString>
#include <fmt/color.h>

editProjectDialogViewmodel::editProjectDialogViewmodel(QObject* parent, prismModelProxy<MLProject>* model)
    : QObject(parent)
{

    m_model = model;

    setEditModel(new prismModelProxy<MLProject>(this, std::make_shared<MLProject>(*model->instance()))); //深复制一份用于编辑
}

prismModelProxy<MLProject>* editProjectDialogViewmodel::editModel() const
{
    return m_editModel;
}

void editProjectDialogViewmodel::setEditModel(prismModelProxy<MLProject>* newEditModel)
{
    if (m_editModel == newEditModel)
        return;
    m_editModel = newEditModel;
    emit editModelChanged();
}

void editProjectDialogViewmodel::save()
{
    auto& left = *this->m_model->instance();
    auto& right = *editModel()->instance();
    prism::reflection::copy(left, right);

    QDir dir(QString::fromStdString(right.workDir));
    if (!dir.exists())
        dir.mkpath(QString::fromStdString(right.workDir));

    this->m_model->update();
}
