#include "mainviewmodel.h"
#include <QApplication>
#include <QDebug>
#include <QDir>
#include <QImage>
#include <QRegularExpressionMatch>
#include <QStandardPaths>
#include <QString>
#include <QUuid>
#include <fmt/core.h>
#include <math.h>
#include <opencv2/opencv.hpp>
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

    setModelList(new prismModelListProxy<MLProjectModel>(this));
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
    //用户文件夹文档目录
    QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);

    std::shared_ptr<MLProject> proj = std::make_shared<MLProject>();
    proj->guid = QUuid::createUuid().toString().toStdString();
    proj->name = "项目-";
    appConf()->instance()->projects->appendItem(proj);

    std::string folder = fmt::format("{}/{}/{}", documentsPath.toStdString(), "label-image-projects", proj->name);
    QDir dir(QString::fromStdString(folder));
    if (!dir.exists())
        dir.mkpath(QString::fromStdString(folder));
    proj->workDir = folder;

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
        setActiveProject(rvm);
        this->loadImages(QString::fromStdString(rvm->instance()->imageDir));
        rvm->instance()->status = ENUM_projectStatus::Activated;
    }
    else
    {
        rvm->instance()->status = ENUM_projectStatus::Normal;
        setActiveProject(nullptr);
    }
    rvm->update();

    loadModelList();
    saveProjects();
}

void mainViewModel::onclickImg(prismModelProxy<MLProjectImg>* img)
{
    if (!img)
        return;
    // 加载图像
    std::shared_ptr<cv::Mat> image = std::make_shared<cv::Mat>();
    *image = cv::imread(img->instance()->fullPath, cv::IMREAD_COLOR);

    // qDebug() << QString::fromStdString(img->instance()->fullPath);
    prism::qt::ui::img_frame_info frame;
    frame.pixelType = prism::qt::ui::ENUM_PixelType::bgr8;
    frame.buffer_handel = std::static_pointer_cast<void>(image);
    frame.buffer = image->data;
    frame.height = image->rows;
    frame.width = image->cols;

    std::shared_ptr<prism::qt::ui::img_buffer_Info> buf;
    if (mainTabIndex() == 0) //标注
        buf = prism::qt::ui::img_buffer_Info::infos[this->m_label_img_buf_sn.toStdString().c_str()];
    else if (mainTabIndex() == 2) //预测
        std::shared_ptr<prism::qt::ui::img_buffer_Info> buf = prism::qt::ui::img_buffer_Info::infos[this->m_predict_img_buf_sn.toStdString().c_str()];

    if (!buf)
        buf = std::make_shared<prism::qt::ui::img_buffer_Info>();
    {
        std::unique_lock<std::mutex> lk(buf->buffer_mux);
        buf->frames.push_back(frame);
    }
    buf->buffer_cv.notify_one();
}

void mainViewModel::add_nms_box(prismModelListProxy<MLProjectImgNMSBox>* boxs, int x, int y, int width, int height, int classification, int imageWidth, int imageHeight, QString img_path)
{
    if (!boxs)
        return;
    std::shared_ptr<MLProjectImgNMSBox> box = std::make_shared<MLProjectImgNMSBox>();
    box->x = x;
    box->y = y;
    box->width = width;
    box->height = height;
    box->imageWidth = imageWidth;
    box->imageHeight = imageHeight;
    box->classificationId = classification;
    box->img_path = img_path;
    boxs->appendItem(box);
}

void mainViewModel::save_boxs(prismModelListProxy<MLProjectImgNMSBox>* boxs, QString imagePath, QString suffix)
{
    std::string labelString;
    int i = 0;
    if (!boxs)
        return;
    if (!boxs->list())
        return;
    for (std::shared_ptr<prismModelProxy<MLProjectImgNMSBox>> box : *boxs->list())
    {
        if (i)
        {
            labelString += "\n";
        }
        ++i;
        std::shared_ptr<MLProjectImgNMSBox> m = box->instance();
        std::string sublabelString;
        if (suffix == "txt")
        {
            sublabelString = fmt::format("{} {} {} {} {}",
                                         m->classificationId,
                                         (m->x + m->width / 2) * 1.0 / m->imageWidth,
                                         (m->y + m->height / 2) * 1.0 / m->imageHeight,
                                         m->width * 1.0 / m->imageWidth,
                                         m->height * 1.0 / m->imageHeight);
        }
        else if (suffix == "predict")
        {
            sublabelString = fmt::format("{} {} {} {} {} {}",
                                         m->classificationId,
                                         (m->x + m->width / 2) * 1.0 / m->imageWidth,
                                         (m->y + m->height / 2) * 1.0 / m->imageHeight,
                                         m->width * 1.0 / m->imageWidth,
                                         m->height * 1.0 / m->imageHeight,
                                         m->confidence);
        }
        labelString += sublabelString;
    }
    QString labelPath = imagePath.replace(QRegExp(R"(([^.]+)$)"), suffix); // txt or predict format
    QFile file(imagePath);
    if (boxs->list()->size())
    {
        // 以写入模式打开文件，如果文件存在则覆盖，如果不存在则创建
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        {
            qDebug() << "Cannot open file for writing:" << file.errorString();
            return;
        }
        // 使用 QTextStream 来写入数据
        QTextStream out(&file);
        out << QString::fromStdString(labelString);
        // 关闭文件
        file.close();
    }
    else
    {

        if (!file.remove(labelPath))
        {
            qDebug() << "文件删除失败:" << labelPath;
        }
    }
}

int mainViewModel::add_classification()
{
    if (!this->activeProject())
        return -1;
    std::shared_ptr<MLProjectClassification> classification = std::make_shared<MLProjectClassification>();
    activeProject()->instance()->classifications->appendItem(classification);
    return static_cast<int>(activeProject()->instance()->classifications->list()->size() - 1);
}

bool mainViewModel::loadImages(QString imageFolder)
{
    if (!imageFolder.isNull() && !imageFolder.isEmpty())
    {
        //如果目录存在,加载训练用的图片
        QDir directory(imageFolder);
        if (!directory.exists())
        {
            qDebug() << "目录不存在";
            return false;
        }
        // 获取目录中的所有文件条目
        QFileInfoList fileList = directory.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
        // 遍历并打印出完整路径和文件名

        activeProject()->instance()->trainImgs->pub_beginResetModel();
        activeProject()->instance()->trainImgs->removeAllItemsNotNotify();
        foreach (QFileInfo fileInfo, fileList)
        {
            QString filePath = fileInfo.absoluteFilePath();
            QString fileName = fileInfo.fileName();
            if (fileName.contains(".jpg") || fileName.contains(".jpeg") || fileName.contains(".png") || fileName.contains(".bmp"))
            {
                std::shared_ptr<MLProjectImg> img = std::make_shared<MLProjectImg>();
                img->displayName = fileName.toStdString();
                img->fullPath = filePath.toStdString();

                {
                    QString labelFilePath = filePath;
                    labelFilePath = labelFilePath.replace(QRegExp(R"([^.]+$)"), "txt");
                    // qDebug() << "label file full path:" << labelFilePath;
                    QFile labelFile(labelFilePath);
                    if (labelFile.exists())
                    {
                        labelFile.open(QFile::ReadOnly);
                        QList<QByteArray> lines = labelFile.readAll().split('\n');
                        labelFile.close();
                        for (QByteArray& line : lines)
                        {
                            QString qline = QString::fromUtf8(line);
                            if (qline.isNull() || qline.isEmpty())
                                continue;
                            QList<QByteArray> datas = line.split(' ');
                            std::shared_ptr<MLProjectImgNMSBox> box = std::make_shared<MLProjectImgNMSBox>();
                            box->classificationId = datas[0].toInt();
                            double cx = datas[1].toDouble();
                            double cy = datas[2].toDouble();
                            double width = datas[3].toDouble();
                            double height = datas[4].toDouble();
                            QImage readimg(filePath);
                            box->x = (cx - width / 2) * readimg.width();
                            box->y = (cy - height / 2) * readimg.height();
                            box->width = width * readimg.width();
                            box->height = height * readimg.height();
                            box->imageWidth = readimg.width();
                            box->imageHeight = readimg.height();
                            box->img_path = filePath;
                            box->label_path = labelFilePath;
                            img->nms_boxs->appendItemNotNotify(box);
                        }
                    }
                }
                {
                    QString labelFilePath = filePath;
                    labelFilePath = labelFilePath.replace(QRegExp(R"([^.]+$)"), "predict");
                    // qDebug() << "label file full path:" << labelFilePath;
                    QFile labelFile(labelFilePath);
                    if (labelFile.exists())
                    {
                        labelFile.open(QFile::ReadOnly);
                        QList<QByteArray> lines = labelFile.readAll().split('\n');
                        labelFile.close();
                        for (QByteArray& line : lines)
                        {
                            QString qline = QString::fromUtf8(line);
                            if (qline.isNull() || qline.isEmpty())
                                continue;
                            QList<QByteArray> datas = line.split(' ');
                            std::shared_ptr<MLProjectImgNMSBox> box = std::make_shared<MLProjectImgNMSBox>();
                            box->classificationId = datas[0].toInt();
                            double cx = datas[1].toDouble();
                            double cy = datas[2].toDouble();
                            double width = datas[3].toDouble();
                            double height = datas[4].toDouble();
                            double conf = datas[5].toDouble();
                            QImage readimg(filePath);
                            box->x = (cx - width / 2) * readimg.width();
                            box->y = (cy - height / 2) * readimg.height();
                            box->width = width * readimg.width();
                            box->height = height * readimg.height();
                            box->imageWidth = readimg.width();
                            box->imageHeight = readimg.height();
                            box->img_path = filePath;
                            box->label_path = labelFilePath;
                            box->confidence = conf;
                            img->predict_boxs->appendItemNotNotify(box);
                        }
                    }
                }
                activeProject()->instance()->trainImgs->appendItemNotNotify(img);
            }
        }
        activeProject()->instance()->trainImgs->pub_endResetModel();
        return true;
    }
    else
        return false;
}

void mainViewModel::train()
{
    QString trainLogRootDirStr = QString::fromStdString(fmt::format("{}/train_logs", activeProject()->instance()->workDir));
    QDir trainLogRootDir(trainLogRootDirStr);
    if (!trainLogRootDir.exists())
        trainLogRootDir.mkpath(trainLogRootDirStr);

    // 获取目录中的所有目录条目
    QStringList subDirs = trainLogRootDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    // 生成新的训练的目录
    int log_num = 0;
    foreach (QString subdir, subDirs)
    {
        QRegularExpression regex("log_(\\d+)$");
        QRegularExpressionMatch match = regex.match(subdir);
        if (match.hasMatch())
        {
            int number = match.captured(1).toInt();
            if (number > log_num)
                log_num = number;
        }
    }

    //创建目录
    QString trainLogDirStr = QString::fromStdString(fmt::format("{}/train_logs/log_{}", activeProject()->instance()->workDir, log_num + 1));
    QDir trainLogDir(trainLogDirStr);
    if (!trainLogDir.exists())
        trainLogDir.mkpath(trainLogDirStr);

    QString trainLogTrainDirStr = QString::fromStdString(fmt::format("{}/{}", trainLogDirStr.toStdString(), "train"));
    QDir trainLogTrainDir(trainLogTrainDirStr);
    if (!trainLogTrainDir.exists())
        trainLogTrainDir.mkpath(trainLogTrainDirStr);

    QString trainLogValDirStr = QString::fromStdString(fmt::format("{}/{}", trainLogDirStr.toStdString(), "val"));
    QDir valLogvalDir(trainLogValDirStr);
    if (!valLogvalDir.exists())
        valLogvalDir.mkpath(trainLogValDirStr);

    QString testLogtestDirStr = QString::fromStdString(fmt::format("{}/{}", trainLogDirStr.toStdString(), "test"));
    QDir testLogtestDir(testLogtestDirStr);
    if (!testLogtestDir.exists())
        testLogtestDir.mkpath(testLogtestDirStr);

    QString classificationStr;
    int i = 0;
    for (std::shared_ptr<prismModelProxy<MLProjectClassification>> item : *activeProject()->instance()->classifications->list())
    {
        if (i)
            classificationStr += "\n";
        classificationStr += QString::fromStdString(fmt::format("  {}: {}", i, item->instance()->name));
        ++i;
    }

    //[1] 生成 yaml
    std::string yamlContent = fmt::format(
        "path: {}\n"
        "train: {}\n"
        "val: {}\n"
        "test: {}\n"
        "names:\n"
        "{}",
        trainLogDirStr.toStdString(),
        "train",
        "val",
        "", classificationStr.toStdString());

    QString yamlPath = trainLogDirStr + "/yolo.yaml";
    QFile file(yamlPath);
    // 以写入模式打开文件，如果文件存在则覆盖，如果不存在则创建
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        qDebug() << "Cannot open file for writing:" << file.errorString();
        return;
    }
    // 使用 QTextStream 来写入数据
    QTextStream out(&file);
    out << QString::fromStdString(yamlContent);
    // 关闭文件
    file.close();

    //[3] 复制标注文件到训练目录
    //[4] 复制预先下载好的Yolov8模型到训练目录
    //[5] 调用yolo cli 命令行训练
    sendText2term(QString("cd \"%1\" &&"
                          "cp -rf \"%2/\"  \"%3\" &&"
                          "cp -rf \"%4/\"  \"%5\" &&"
                          "yolo detect train data=yolo.yaml model=%6  epochs=%7 batch=%8 imgsz=%9 device=%10 "
                          "project=%11 name=%12 \n")
                      .arg(trainLogDirStr, 1)
                      .arg(activeProject()->instance()->imageDir.c_str(), 2)
                      .arg(trainLogTrainDirStr, 3)
                      .arg(activeProject()->instance()->imageDir.c_str(), 4)
                      .arg(trainLogValDirStr, 5)
                      .arg(activeProject()->instance()->modelName.c_str(), 6)
                      .arg(activeProject()->instance()->epochs, 7)
                      .arg(activeProject()->instance()->batchs, 8)
                      .arg(activeProject()->instance()->imgSize, 9)
                      .arg(activeProject()->instance()->device.c_str(), 10)
                      .arg(trainLogDirStr, 11)
                      .arg("result", 12));
}

void mainViewModel::removeAllPredictFiles()
{
    if (!activeProject())
        return;

    QDir directory(QString::fromStdString(activeProject()->instance()->imageDir));
    if (!directory.exists())
    {
        qDebug() << "目录不存在";
        return;
    }
    // 获取目录中的所有文件条目
    QFileInfoList fileList = directory.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
    // 遍历并打印出完整路径和文件名
    foreach (QFileInfo fileInfo, fileList)
    {
        QString filePath = fileInfo.absoluteFilePath();
        QString fileName = fileInfo.fileName();
        if (fileName.contains(".predict"))
        {
            QFile f(filePath);
            if (!f.remove(filePath))
            {
                qDebug() << ".predict file remove failed:" << filePath;
            }
        }
    }
}

void mainViewModel::mergeAllPredictFiles()
{
    if (!activeProject())
        return;
    for (std::shared_ptr<prismModelProxy<MLProjectImg>> item : *activeProject()->instance()->trainImgs->list())
    {
        item->instance()->nms_boxs->pub_beginResetModel();
        for (auto predictBox : *item->instance()->predict_boxs->list())
        {
            item->instance()->nms_boxs->appendItem(predictBox->instance());
        }
        item->instance()->nms_boxs->pub_endResetModel();

        item->instance()->predict_boxs->pub_beginResetModel();
        item->instance()->predict_boxs->removeAllItemsNotNotify();
        item->instance()->predict_boxs->pub_endResetModel();

        QString imgdir = QString::fromStdString(item->instance()->fullPath);
        this->save_boxs(item->instance()->nms_boxs.get(), imgdir, "txt");
        this->save_boxs(item->instance()->predict_boxs.get(), imgdir, "predict");
    }
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

const QString& mainViewModel::predict_img_buf_sn() const
{
    return m_predict_img_buf_sn;
}

void mainViewModel::setPredict_img_buf_sn(const QString& newPredict_img_buf_sn)
{
    if (m_predict_img_buf_sn == newPredict_img_buf_sn)
        return;
    m_predict_img_buf_sn = newPredict_img_buf_sn;
    emit predict_img_buf_snChanged();
}

int mainViewModel::mainTabIndex() const
{
    return m_mainTabIndex;
}

void mainViewModel::setMainTabIndex(int newMainTabIndex)
{
    if (m_mainTabIndex == newMainTabIndex)
        return;
    m_mainTabIndex = newMainTabIndex;
    emit mainTabIndexChanged();
}

prismModelListProxy<MLProjectModel>* mainViewModel::modelList() const
{
    return m_modelList;
}

void mainViewModel::setModelList(prismModelListProxy<MLProjectModel>* newModelList)
{
    if (m_modelList == newModelList)
        return;
    m_modelList = newModelList;
    emit modelListChanged();
}

void mainViewModel::loadModelList()
{
    std::vector<std::string> preModelList = {
        "yolov8n.pt",
        "yolov8s.pt",
        "yolov8m.pt",
        "yolov8l.pt"};
    modelList()->pub_beginResetModel();
    //[0] 删除列表原有的模型
    modelList()->removeAllItemsNotNotify();

    //[1] 加载yolov8预训练模型
    for (const std::string& item : preModelList)
    {
        std::shared_ptr<MLProjectModel> model = std::make_shared<MLProjectModel>();
        model->displayName = item;
        model->fullPath = fmt::format("{}/{}", QApplication::instance()->applicationDirPath().toStdString(), model->displayName);
        modelList()->appendItemNotNotify(model);
    }

    //[2] 加载项目目录的训练的模型
    std::string logRoot = fmt::format("{}/train_logs", activeProject()->instance()->workDir);
    QDir directory(QString::fromStdString(logRoot));
    if (!directory.exists())
    {
        qDebug() << "目录不存在";
        modelList()->pub_endResetModel();
        return;
    }
    // 获取目录中的所有文件条目
    // QFileInfoList fileList = directory.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
    QStringList dirs = directory.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    std::sort(dirs.begin(), dirs.end(), [](const QString& str1, const QString& str2) {
        QRegularExpression regex("(\\d+)$");
        QRegularExpressionMatch match;

        match = regex.match(str1);
        int num1 = match.captured(1).toInt();

        match = regex.match(str2);
        int num2 = match.captured(1).toInt();

        return num1 < num2;
    });
    // 遍历并打印出完整路径和文件名

    activeProject()->instance()->trainImgs->pub_beginResetModel();
    foreach (const QString& logDir, dirs)
    {
        QString modeldir = QString("%1/%2").arg(logRoot.c_str()).arg(logDir);
        QString modelFullPath = QString("%1/%2/result/weights/best.pt").arg(logRoot.c_str()).arg(logDir);
        QFile modelfile(modelFullPath);
        if (!modelfile.exists())
            continue;
        // qDebug() << modelFullPath;
        std::shared_ptr<MLProjectModel> model = std::make_shared<MLProjectModel>();

        model->displayName = logDir.toStdString();
        model->fullPath = modelFullPath.toStdString();
        model->dir = modeldir.toStdString();

        QString modelargsFullPath = QString("%1/%2/result/args.yaml").arg(logRoot.c_str()).arg(logDir);
        QFile argsFile(modelargsFullPath);
        if (!argsFile.exists())
            continue;
        if (!argsFile.open(QFile::QFileDevice::ReadOnly))
            continue;

        QString argsFileContent = argsFile.readAll();
        // qDebug() << argsFileContent;
        QRegularExpression regex;

        regex = QRegularExpression("^\\s*model: (.*)$", QRegularExpression::MultilineOption);
        QString baseOn = regex.match(argsFileContent).captured(1);

        regex = QRegularExpression("^\\s*epochs: (.*)$", QRegularExpression::MultilineOption);
        QString epochs = regex.match(argsFileContent).captured(1);

        regex = QRegularExpression("^\\s*batch: (.*)$", QRegularExpression::MultilineOption);
        QString batch = regex.match(argsFileContent).captured(1);

        regex = QRegularExpression("^\\s*imgsz: (.*)$", QRegularExpression::MultilineOption);
        QString imgSize = regex.match(argsFileContent).captured(1);

        // qDebug() << "baseon:" << baseOn << "   epochs:" << epochs << "   batch:" << batch << "   imageSize:" << imgSize;

        model->baseOn = baseOn.toStdString();
        model->epochs = epochs.toInt();
        model->batchs = batch.toInt();
        model->imgSize = imgSize.toInt();
        modelList()->appendItemNotNotify(model);
        argsFile.close();
    }

    modelList()->pub_endResetModel();
}

bool mainViewModel::tabindex0reloadImages() const
{
    return m_tabindex0reloadImages;
}

void mainViewModel::setTabindex0reloadImages(bool newTabindex0reloadImages)
{
    if (m_tabindex0reloadImages == newTabindex0reloadImages)
        return;
    m_tabindex0reloadImages = newTabindex0reloadImages;
    emit tabindex0reloadImagesChanged();
}

bool mainViewModel::reloading() const
{
    return m_reloading;
}

void mainViewModel::setReloading(bool newReloading)
{
    if (m_reloading == newReloading)
        return;
    m_reloading = newReloading;
    emit reloadingChanged();
}
