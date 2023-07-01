#ifndef FLUTTER_PLUGIN_TBIB_DOWNLOADER_PLUGIN_H_
#define FLUTTER_PLUGIN_TBIB_DOWNLOADER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace tbib_downloader {

class TbibDownloaderPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  TbibDownloaderPlugin();

  virtual ~TbibDownloaderPlugin();

  // Disallow copy and assign.
  TbibDownloaderPlugin(const TbibDownloaderPlugin&) = delete;
  TbibDownloaderPlugin& operator=(const TbibDownloaderPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace tbib_downloader

#endif  // FLUTTER_PLUGIN_TBIB_DOWNLOADER_PLUGIN_H_
