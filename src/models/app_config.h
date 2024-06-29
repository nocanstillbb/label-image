#ifndef APP_CONFIG_H
#define APP_CONFIG_H

#include <memory>
#include <prism/prism.hpp>
#include <prism/qt/core/hpp/prismModelListProxy.hpp>
#include <prism/qt/core/hpp/prismQt.hpp>

using prism::qt::core::prismModelListProxy;

struct MLProject
{
    std::string name;
    std::string workDir;
    std::string trainFolder = "train";
    std::string valFolder = "val";
    std::string testFolder = "test";
    int batchs = 4;
    int epothis = 4;
};
PRISMQT_CLASS(MLProject)
PRISM_FIELDS(MLProject, name, workDir, trainFolder, valFolder, testFolder, batchs, epothis)

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
