#ifndef MAINVIEWMODEL_H
#define MAINVIEWMODEL_H

#include "models/app_config.h"
#include <QObject>
#include <prism/qt/core/hpp/prismModelProxy.hpp>
#include <prism/qt/core/hpp/prismQt.hpp>

using prism::qt::core::prismModelProxy;

class mainViewModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(prismModelProxy<App_config>* appConf READ appConf WRITE setAppConf NOTIFY appConfChanged)
    Q_PROPERTY(prismModelProxy<MLProject>* activeProject READ activeProject WRITE setActiveProject NOTIFY activeProjectChanged)
    Q_PROPERTY(QString label_img_buf_sn READ label_img_buf_sn WRITE setLabel_img_buf_sn NOTIFY label_img_buf_snChanged)

  private:
    prismModelProxy<App_config>* m_appConf = nullptr;
    prismModelProxy<MLProject>* m_activeProject = nullptr;

    QString m_label_img_buf_sn;

  public:
    explicit mainViewModel(QObject* parent = nullptr);

    prismModelProxy<App_config>* appConf() const;
    void setAppConf(prismModelProxy<App_config>* newAppConf);

    void setActiveProject(prismModelProxy<MLProject>* newActiveProject);
    prismModelProxy<MLProject>* activeProject() const;

    const QString& label_img_buf_sn() const;
    void setLabel_img_buf_sn(const QString& newLabel_img_buf_sn);

  signals:

    void appConfChanged();

    void activeProjectChanged();

    void label_img_buf_snChanged();

  public slots:
    void displayFirstImg();
    void openEditProjectWin(prismModelProxy<MLProject>* rvm);
    int addProject();
    void removeProject(int index);
    void saveProjects();
    void activeProjectRvm(prismModelProxy<MLProject>* rvm);
    void onclickImg(prismModelProxy<MLProjectImg>* img);
    void add_nms_box(prismModelListProxy<MLProjectImgNMSBox>* boxs, int x, int y, int width, int height, int classification);
    int add_classification();
};

#endif // MAINVIEWMODEL_H
