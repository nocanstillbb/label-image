#include "mainviewmodel.h"
#include <QDebug>
#include <QDir>
#include <QImage>
#include <QString>
#include <QUuid>
#include <fmt/core.h>
#include <prism/container.hpp>
#include <prism/qt/core/hpp/prismModelListProxy.hpp>
#include <prism/qt/ui/helper/cpp_utility.h>
#include <prism/qt/ui/img_buffer_Info.h>
#include <viewmodels/editprojectdialogviewmodel.h>

mainViewModel::mainViewModel(QObject* parent)
    : QObject(parent)
{

    prismModelProxy<App_config>* conf = new prismModelProxy<App_config>(this, App_config::instance());
    for (std::shared_ptr<prismModelProxy<MLProject>> item : *App_config::instance()->projects->list())
    {
        item->instance()->actived = false;
    }
    setAppConf(conf);
}

prismModelProxy<App_config>* mainViewModel::appConf() const
{
    return m_appConf;
}

void mainViewModel::setAppConf(prismModelProxy<App_config>* newAppConf)
{
    if (m_appConf == newAppConf)
        return;
    m_appConf = newAppConf;
    emit appConfChanged();
}

void mainViewModel::openEditProjectWin(prismModelProxy<MLProject>* rvm)
{
    editProjectDialogViewmodel vm(this, rvm);
    std::shared_ptr<prism::qt::ui::cpp_utility> qu = prism::Container::get()->resolve_object<prism::qt::ui::cpp_utility>();
    qu->showQmlDialog("qrc:/label-image/views/editProjectDialog.qml", &vm);
}

int mainViewModel::addProject()
{
    std::shared_ptr<MLProject> proj = std::make_shared<MLProject>();
    proj->guid = QUuid::createUuid().toString().toStdString();
    proj->name = "项目-";
    proj->workDir = QDir::currentPath().toStdString();
    appConf()->instance()->projects->appendItem(proj);

    openEditProjectWin(appConf()->instance()->projects->list()->last().get());
    return static_cast<int>(appConf()->instance()->projects->list()->size() - 1);
}

void mainViewModel::removeProject(int index)
{
    if (index < 0)
        return;
    if (appConf() && appConf()->instance()->projects && appConf()->instance()->projects->list()->size() - 1 >= index)
    {
        appConf()->instance()->projects->removeItemAt(index);
    }
}

void mainViewModel::saveProjects()
{
    App_config::save(appConf()->instance());
}

void mainViewModel::activeProjectRvm(prismModelProxy<MLProject>* rvm)
{
    setActiveProject(nullptr);
    for (std::shared_ptr<prismModelProxy<MLProject>> item : *appConf()->instance()->projects->list())
    {
        if (rvm->instance().get() != item->instance().get())
        {
            item->instance()->actived = false;
            item->instance()->status = ENUM_projectStatus::Normal;
            item->update();
        }
    }
    if (!rvm)
        return;
    rvm->instance()->actived = true;
    if (rvm->instance()->actived)
    {
        //如果目录存在,加载训练用的图片
        QDir directory(QString::fromStdString(fmt::format("{}/{}", rvm->instance()->workDir, rvm->instance()->trainFolder)));
        if (!directory.exists())
        {
            qDebug() << "目录不存在";
            return;
        }
        // 获取目录中的所有文件条目
        QFileInfoList fileList = directory.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
        // 遍历并打印出完整路径和文件名

        rvm->instance()->trainImgs->removeAllItems();
        foreach (QFileInfo fileInfo, fileList)
        {
            QString filePath = fileInfo.absoluteFilePath();
            QString fileName = fileInfo.fileName();
            std::shared_ptr<MLProjectImg> img = std::make_shared<MLProjectImg>();
            img->displayName = fileName.toStdString();
            img->fullPath = filePath.toStdString();
            // qDebug() << "File Path:" << filePath << ", File Name:" << fileName;
            rvm->instance()->trainImgs->appendItemNotNotify(img);
        }
        rvm->instance()->status = ENUM_projectStatus::Activated;
        setActiveProject(rvm);
    }
    else
    {
        rvm->instance()->status = ENUM_projectStatus::Normal;
        setActiveProject(nullptr);
    }
    rvm->update();
    saveProjects();
}

void mainViewModel::onclickImg(prismModelProxy<MLProjectImg>* img)
{
    if (!img)
        return;
    // 加载图像
    std::shared_ptr<QImage> image = std::make_shared<QImage>();
    if (!image->load(QString::fromStdString(img->instance()->fullPath)))
    {
        qWarning("加载图片失败");
    }

    // 确保图像格式为 RGB888 或者其他适合的格式
    *image = image->convertToFormat(QImage::Format_RGB888);

    // qDebug() << QString::fromStdString(img->instance()->fullPath);
    prism::qt::ui::img_frame_info frame;
    frame.pixelType = prism::qt::ui::ENUM_PixelType::rgb8;
    frame.buffer_handel = std::static_pointer_cast<void>(image);
    frame.buffer = image->bits();
    frame.height = image->height();
    frame.width = image->width();

    std::shared_ptr<prism::qt::ui::img_buffer_Info> buf = prism::qt::ui::img_buffer_Info::infos[this->m_label_img_buf_sn.toStdString().c_str()];
    if (!buf)
        buf = std::make_shared<prism::qt::ui::img_buffer_Info>();
    {
        std::unique_lock<std::mutex> lk(buf->buffer_mux);
        buf->frames.push_back(frame);
    }
    buf->buffer_cv.notify_one();
}

void mainViewModel::add_nms_box(prismModelListProxy<MLProjectImgNMSBox>* boxs, int x, int y, int width, int height, int classification)
{
    if (!boxs)
        return;
    std::shared_ptr<MLProjectImgNMSBox> box = std::make_shared<MLProjectImgNMSBox>();
    box->x = x;
    box->y = y;
    box->width = width;
    box->height = height;
    box->classificationId = classification;
    boxs->appendItem(box);
}

int mainViewModel::add_classification()
{
    if (!this->activeProject())
        return -1;
    std::shared_ptr<MLProjectClassification> classification = std::make_shared<MLProjectClassification>();
    activeProject()->instance()->classifications->appendItem(classification);
    return static_cast<int>(activeProject()->instance()->classifications->list()->size() - 1);
}

void mainViewModel::displayFirstImg()
{
    if (activeProject() && activeProject()->instance())
    {
        for (std::shared_ptr<prismModelProxy<MLProjectImg>> item : *activeProject()->instance()->trainImgs->list())
        {
            onclickImg(item.get());
            break;
        }
    }
}

void mainViewModel::setActiveProject(prismModelProxy<MLProject>* newActiveProject)
{
    if (m_activeProject == newActiveProject)
        return;
    m_activeProject = newActiveProject;
    emit activeProjectChanged();
}

prismModelProxy<MLProject>* mainViewModel::activeProject() const
{
    return m_activeProject;
}

const QString& mainViewModel::label_img_buf_sn() const
{
    return m_label_img_buf_sn;
}

void mainViewModel::setLabel_img_buf_sn(const QString& newLabel_img_buf_sn)
{
    if (m_label_img_buf_sn == newLabel_img_buf_sn)
        return;
    m_label_img_buf_sn = newLabel_img_buf_sn;
    emit label_img_buf_snChanged();
}
