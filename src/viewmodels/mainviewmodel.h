#ifndef MAINVIEWMODEL_H
#define MAINVIEWMODEL_H

//#include "TerminalDisplay.h"
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
    Q_PROPERTY(QString predict_img_buf_sn READ predict_img_buf_sn WRITE setPredict_img_buf_sn NOTIFY predict_img_buf_snChanged)
    Q_PROPERTY(int mainTabIndex READ mainTabIndex WRITE setMainTabIndex NOTIFY mainTabIndexChanged)
    Q_PROPERTY(prismModelListProxy<MLProjectModel>* modelList READ modelList WRITE setModelList NOTIFY modelListChanged)
    Q_PROPERTY(bool tabindex0reloadImages READ tabindex0reloadImages WRITE setTabindex0reloadImages NOTIFY tabindex0reloadImagesChanged)
    Q_PROPERTY(bool reloading READ reloading WRITE setReloading NOTIFY reloadingChanged)

  private:
    prismModelProxy<App_config>* m_appConf = nullptr;
    prismModelProxy<MLProject>* m_activeProject = nullptr;

    QString m_label_img_buf_sn;

    QString m_predict_img_buf_sn;

    int m_mainTabIndex = 0;

    prismModelListProxy<MLProjectModel>* m_modelList = nullptr;

    bool m_tabindex0reloadImages = false;

    bool m_reloading = true;

  public:
    explicit mainViewModel(QObject* parent = nullptr);

    prismModelProxy<App_config>* appConf() const;
    void setAppConf(prismModelProxy<App_config>* newAppConf);

    void setActiveProject(prismModelProxy<MLProject>* newActiveProject);
    prismModelProxy<MLProject>* activeProject() const;

    const QString& label_img_buf_sn() const;
    void setLabel_img_buf_sn(const QString& newLabel_img_buf_sn);

    const QString& predict_img_buf_sn() const;
    void setPredict_img_buf_sn(const QString& newPredict_img_buf_sn);

    int mainTabIndex() const;
    void setMainTabIndex(int newMainTabIndex);

    prismModelListProxy<MLProjectModel>* modelList() const;
    void setModelList(prismModelListProxy<MLProjectModel>* newModelList);

    bool tabindex0reloadImages() const;
    void setTabindex0reloadImages(bool newTabindex0reloadImages);

    bool reloading() const;
    void setReloading(bool newReloading);

  signals:

    void appConfChanged();

    void activeProjectChanged();

    void label_img_buf_snChanged();

    void sendText2term(QString cmd);
    void windowClose(QVariant e);

    void predict_img_buf_snChanged();

    void mainTabIndexChanged();

    void modelListChanged();

    void tabindex0reloadImagesChanged();

    void reloadingChanged();

  public slots:
    void displayFirstImg();
    void openEditProjectWin(prismModelProxy<MLProject>* rvm);
    int addProject();
    void removeProject(int index);
    void saveProjects();
    void activeProjectRvm(prismModelProxy<MLProject>* rvm);
    void onclickImg(prismModelProxy<MLProjectImg>* img);
    void add_nms_box(prismModelListProxy<MLProjectImgNMSBox>* boxs, int x, int y, int width, int height, int classification, int imageWidth, int imageHeight, QString img_path);
    void save_boxs(prismModelListProxy<MLProjectImgNMSBox>* boxs, QString imagePath, QString suffix = "txt");
    int add_classification();
    bool loadImages(QString imageFolder);
    bool loadImage(prismModelProxy<MLProjectImg>* imgRvm);
    void loadModelList();
    void train();
    void removeAllPredictFiles();
    void mergeAllPredictFiles();
};

#endif // MAINVIEWMODEL_H
