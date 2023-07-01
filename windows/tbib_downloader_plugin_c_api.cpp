#include "include/tbib_downloader/tbib_downloader_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "tbib_downloader_plugin.h"

void TbibDownloaderPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  tbib_downloader::TbibDownloaderPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
