#ifndef APP_CONFIG_H
#define APP_CONFIG_H

#include <memory>
#include <prism/prism.hpp>
#include <prism/prismJson.hpp>
#include <prism/qt/core/hpp/prismModelListProxy.hpp>
#include <prism/qt/core/hpp/prismQt.hpp>

using prism::qt::core::prismModelListProxy;
using prism::qt::core::prismModelProxy;

// Normal, activated, training, testing, verifying
enum class ENUM_projectStatus
{
    Normal = 0,
    Activated,
    Training,
    Testing,
    Validating
};

PRISMQT_ENUM(ENUM_projectStatus)
PRISM_ENUM(ENUM_projectStatus, {{ENUM_projectStatus::Normal, "Normal"},
                                {ENUM_projectStatus::Activated, "Activated"},
                                {ENUM_projectStatus::Training, "Training"},
                                {ENUM_projectStatus::Testing, "Testing"},
                                {ENUM_projectStatus::Validating, "Validating"}})

struct MLProjectClassification
{
    std::string name = "新的分类";
    std::string color = "black";
};
PRISMQT_CLASS(MLProjectClassification)
PRISM_FIELDS(MLProjectClassification, name, color)
struct MLProjectImgNMSBox
{
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
    int imageWidth = 1;
    int imageHeight = 1;
    double confidence;
    int classificationId = 0;
    bool isSelected = false;
    QString img_path;
    QString label_path;
};
PRISMQT_CLASS(MLProjectImgNMSBox)
PRISM_IGNORE_JSON_FIELD(MLProjectImgNMSBox, isSelected)
PRISM_IGNORE_JSON_FIELD(MLProjectImgNMSBox, img_path)
PRISM_IGNORE_JSON_FIELD(MLProjectImgNMSBox, label_path)
PRISM_FIELDS(MLProjectImgNMSBox, x, y, width, height, confidence, classificationId, isSelected, imageWidth, imageHeight, img_path, label_path)

struct MLProjectImg
{
    std::string fullPath;
    std::string displayName;
    std::shared_ptr<prismModelListProxy<MLProjectImgNMSBox>> nms_boxs = std::make_shared<prismModelListProxy<MLProjectImgNMSBox>>();
    std::shared_ptr<prismModelListProxy<MLProjectImgNMSBox>> predict_boxs = std::make_shared<prismModelListProxy<MLProjectImgNMSBox>>();
};
PRISMQT_CLASS(MLProjectImg)
PRISM_FIELDS(MLProjectImg, fullPath, displayName, nms_boxs, predict_boxs)

struct MLProjectModel
{
    std::string displayName;
    std::string fullPath;
    std::string dir;
    std::string baseOn;
    int batchs = -1;
    int epochs = -1;
    int imgSize = 640;
};
PRISMQT_CLASS(MLProjectModel)
PRISM_FIELDS(MLProjectModel, displayName, fullPath, dir, baseOn, batchs, epochs, imgSize)

struct MLProject
{
    std::string guid;
    std::string name;
    std::string workDir;  //项目目录
    std::string imageDir; //图片目录
    std::string trainFolder = "train";
    std::string valFolder = "val";
    std::string testFolder = "test";
    int batchs = 16;
    int epochs = 100;
    int imgSize = 640;
    std::string modelName = "yolov8n.pt";
    std::string device = "cpu";

    bool actived = false;
    bool isbusy = false;
    int tabindex = 0;
    ENUM_projectStatus status = ENUM_projectStatus::Normal;

    std::shared_ptr<prismModelListProxy<MLProjectImg>> trainImgs = std::make_shared<prismModelListProxy<MLProjectImg>>();

    std::shared_ptr<prismModelListProxy<MLProjectClassification>> classifications = std::make_shared<prismModelListProxy<MLProjectClassification>>();
};
PRISMQT_CLASS(MLProject)
PRISM_IGNORE_JSON_FIELD(MLProject, trainImgs)
PRISM_IGNORE_JSON_FIELD(MLProject, isbusy)
PRISM_FIELDS(MLProject, guid, name, workDir, imageDir, trainFolder, valFolder, testFolder, batchs, epochs, imgSize, modelName, device, actived, isbusy, tabindex, status, trainImgs, classifications)

struct App_config
{
    std::string device = "cpu";
    std::shared_ptr<prismModelListProxy<MLProject>> projects = std::make_shared<prismModelListProxy<MLProject>>();
    static std::shared_ptr<App_config> fromfile();
    static std::shared_ptr<App_config> instance();
    static void save(std::shared_ptr<App_config> tos);
};
PRISMQT_CLASS(App_config)
PRISM_FIELDS(App_config, device, projects)

#endif // APP_CONFIG_H
