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

    prismModelProxy<App_config>* m_appConf;

  public:
    explicit mainViewModel(QObject* parent = nullptr);

    prismModelProxy<App_config>* appConf() const;
    void setAppConf(prismModelProxy<App_config>* newAppConf);

  signals:

    void appConfChanged();
};

#endif // MAINVIEWMODEL_H
