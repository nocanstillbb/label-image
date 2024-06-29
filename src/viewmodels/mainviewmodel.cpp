#include "mainviewmodel.h"

mainViewModel::mainViewModel(QObject* parent)
    : QObject(parent)
{
    setAppConf(new prismModelProxy<App_config>(this, App_config::instance()));
    std::shared_ptr<MLProject> proj = std::make_shared<MLProject>();
    proj->batchs = 44;
    proj->epothis = 33;
    proj->name = "测试项目名称";
    proj->testFolder = "测试数据目录";
    proj->trainFolder = "训练数据目录";
    proj->valFolder = "验证数据目录";
    proj->workDir = "工作目录";
    appConf()->instance()->projects->appendItem(proj);

    App_config::save(appConf()->instance());
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
