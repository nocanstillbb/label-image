#include <prism/qt/core/hpp/prismQtJson.hpp>

#ifdef __linux
#include <experimental/filesystem>
#define filesystem experimental::filesystem
#else
#include <filesystem>
#endif

#include <fstream>

#include "app_config.h"

static inline constexpr const char* App_config_file_path = "App_config.json";

std::shared_ptr<App_config> App_config::fromfile()
{

    std::ifstream fs_in(App_config_file_path);
    if (fs_in.is_open())
    {
        std::string content((std::istreambuf_iterator<char>(fs_in)),
                            (std::istreambuf_iterator<char>()));
        fs_in.close();
        return prism::json::fromJsonString<App_config>(content);
    }
    else
    {
        std::ofstream fs_out(App_config_file_path);
        if (fs_out.is_open())
        {
            App_config ac{};
            fs_out << prism::json::toJsonString(ac, 4);
        }
        else
            throw "写入文件失败:";
    }
    return fromfile();
}

std::shared_ptr<App_config> App_config::instance()
{
    static std::shared_ptr<App_config> conf = fromfile();
    return conf;
}

void App_config::save(std::shared_ptr<App_config> tos)
{
    std::ofstream fs_out(App_config_file_path);

    if (fs_out.is_open())
    {
        fs_out << prism::json::toJsonString(*tos, 4);
    }
    else
        throw "写入文件失败:";
}
