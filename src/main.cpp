#include "fileio.h"
#include "monospacefontmanager.h"
#include "viewmodels/mainviewmodel.h"

#ifdef Q_OS_MACX
#include <Qtwidgets/QApplication>
#else
#include <QGuiApplication>
#endif

#include <QLoggingCategory>
#include <QPluginLoader>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QString>
#include <QtDebug>
#include <QtWidgets/QApplication>
#include <prism/container.hpp>
#include <prism/qt/modular/interfaces/intf_module.h>
#include <prism/qt/modular/wrapper.h>
#include <vector>
void regiestTypes();
void set_cool_retro_term_envs();
void set_cool_retro_term_app(QGuiApplication& app, QQmlApplicationEngine& engine);
prism::qt::modular::intfModule* loadplugin(const std::string& module_name);
QString getNamedArgument(QStringList args, QString name, QString defaultName);
QString getNamedArgument(QStringList args, QString name);

int main(int argc, char* argv[])
{
    set_cool_retro_term_envs();

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);
    //#endif

#ifdef Q_OS_MACX
    // QGuiApplication app(argc, argv);
    QApplication app(argc, argv);
#else
    QGuiApplication app(argc, argv);
#endif
    std::shared_ptr<QQmlApplicationEngine> sptr_engine(new QQmlApplicationEngine(), [](auto* p) { p->deleteLater(); });
    prism::Container::get()->register_instance<QQmlApplicationEngine>(sptr_engine);
    app.setAttribute(Qt::AA_MacDontSwapCtrlAndMeta, true);
    set_cool_retro_term_app(app, *sptr_engine);

    // register types
    regiestTypes();

    // viewmodel instance
    mainViewModel vm;
    sptr_engine->rootContext()->setContextProperty("vm", &vm);

    // set startup rul
    prism::qt::modular::wrapper::startupUrl = "qrc:/label-image/views/MainWindow.qml";

    // load plugins
    std::vector<prism::qt::modular::intfModule*> plugins;
    plugins.push_back(loadplugin("prism_qt_core"));
    plugins.push_back(loadplugin("prism_qt_ui"));
    prism::qt::modular::wrapper w(plugins, [&]() {
        static QMetaObject::Connection connection = QObject::connect(
            sptr_engine.get(), &QQmlApplicationEngine::objectCreated, &app, [&](QObject* object, const QUrl& url) {
                if (url.toString() != QString::fromStdString(prism::qt::modular::wrapper::startupUrl))
                    return;
                auto* win = reinterpret_cast<QQuickWindow*>(object);
                if (win)
                {
#ifdef _WIN32
                    win->setVisible(false);
                    win->setOpacity(0);
                    win->setWindowState(Qt::WindowMinimized);
#endif

                    //退出后释放opengl共享纹理
                    // "设置主窗口不释放纹理和场景图,退出后统一释放";
                    win->setPersistentOpenGLContext(true);
                    win->setPersistentSceneGraph(true);
                    std::shared_ptr<QQuickWindow> sp_win(win, [](QQuickWindow* p) { Q_UNUSED(p) });
                    prism::Container::get()->register_instance(sp_win);
                }
                if (!object)
                    app.exit(-1);
                else
                    QObject::disconnect(connection);
            },
            Qt::QueuedConnection);

        sptr_engine->load(QString::fromStdString(prism::qt::modular::wrapper::startupUrl));
        return app.exec();
    });

    int exitCode = w.run();
    return exitCode;
}

void regiestTypes()
{
    qRegisterMetaType<App_config*>("App_config*");
    qRegisterMetaType<prismModelProxy<App_config>*>("prismModelProxy<App_config>*");

    qRegisterMetaType<MLProject*>("MLProject*");
    qRegisterMetaType<prismModelProxy<MLProject>*>("prismModelProxy<MLProject>*");
    qRegisterMetaType<prismModelListProxy<MLProject>*>("prismModelListProxy<MLProject>*");

    qRegisterMetaType<bool*>("bool*");
    qRegisterMetaType<double*>("double*");
    qRegisterMetaType<float*>("float*");
    qRegisterMetaType<int*>("int*");
    qRegisterMetaType<long*>("long*");
    qRegisterMetaType<QString*>("QString*");
    qRegisterMetaType<QEventLoop*>("QEventLoop*");
    qRegisterMetaType<std::vector<int>*>("std::vector<int>*");
    qRegisterMetaType<std::shared_ptr<std::vector<int>>>("std::shared_ptr<std::vector<int>>");
    qRegisterMetaType<prismModelProxy<MLProjectImg>*>("prismModelProxy<MLProjectImg>*");
    qRegisterMetaType<prismModelListProxy<MLProjectImgNMSBox>*>("prismModelListProxy<MLProjectImgNMSBox>*");
}

void set_cool_retro_term_envs()
{
#if defined(Q_OS_MAC)
    // This allows UTF-8 characters usage in OSX.
    setenv("LC_CTYPE", "zh_CN.UTF-8", 1);

#endif
    // This disables QT appmenu under Ubuntu, which is not working with QML apps.
    setenv("QT_QPA_PLATFORMTHEME", "", 1);

    // Disable Connections slot warnings
    QLoggingCategory::setFilterRules("qt.qml.connections.warning=false");

#if defined(Q_OS_LINUX)
    setenv("QSG_RENDER_LOOP", "threaded", 0);
#endif
}
void set_cool_retro_term_app(QGuiApplication& app, QQmlApplicationEngine& engine)
{
    static MonospaceFontManager monospaceFontManager;
    static FileIO fileIO;
    QString appVersion("1.2.0");

    //#if !defined(Q_OS_MAC)
    //    app.setWindowIcon(QIcon::fromTheme("cool-retro-term", QIcon(":../icons/32x32/cool-retro-term.png")));
    //#else
    //    app.setWindowIcon(QIcon(":../icons/32x32/cool-retro-term.png"));
    //#endif

    app.setOrganizationName("label-images");
    app.setOrganizationDomain("label-images");

    // Manage command line arguments from the cpp side
    QStringList args = app.arguments();

    // Manage default command
    QStringList cmdList;
    if (args.contains("-e"))
    {
        cmdList << args.mid(args.indexOf("-e") + 1);
    }
    QVariant command(cmdList.empty() ? QVariant() : cmdList[0]);
    QVariant commandArgs(cmdList.size() <= 1 ? QVariant() : QVariant(cmdList.mid(1)));
    engine.rootContext()->setContextProperty("appVersion", appVersion);
    engine.rootContext()->setContextProperty("defaultCmd", command);
    engine.rootContext()->setContextProperty("defaultCmdArgs", commandArgs);

    engine.rootContext()->setContextProperty("workdir", getNamedArgument(args, "--workdir", "$HOME"));
    engine.rootContext()->setContextProperty("fileIO", &fileIO);
    engine.rootContext()->setContextProperty("monospaceSystemFonts", monospaceFontManager.retrieveMonospaceFonts());

    engine.rootContext()->setContextProperty("devicePixelRatio", app.devicePixelRatio());

    // Manage import paths for Linux and OSX.
    QStringList importPathList = engine.importPathList();
    importPathList.prepend("qrc:/");
    importPathList.prepend(QCoreApplication::applicationDirPath());
    importPathList.prepend("/Users/hbb/Qt/5.15.2/clang_64/qml");
    for (QString& item : importPathList)
    {
        qDebug() << item;
    }
    engine.setImportPathList(importPathList);
}
prism::qt::modular::intfModule* loadplugin(const std::string& module_name)
{

    QString item = QString::fromStdString(module_name);
    QPluginLoader loader(item);
    QObject* plugin = loader.instance();
    if (!plugin)
        qDebug() << "plugin is null : " << loader.errorString();
    prism::qt::modular::intfModule* pi = qobject_cast<prism::qt::modular::intfModule*>(plugin);
    if (pi == nullptr)
        qDebug() << "pi is null";
    else
    {
        pi->setObjectName(item);
        return pi;
    }
    return (prism::qt::modular::intfModule*)nullptr;
}

QString getNamedArgument(QStringList args, QString name, QString defaultName)
{
    int index = args.indexOf(name);
    return (index != -1) ? args[index + 1] : QString(defaultName);
}

QString getNamedArgument(QStringList args, QString name)
{
    return getNamedArgument(args, name, "");
}
