//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <ndi_windows_player/ndi_windows_player_plugin_c_api.h>
#include <nsd_windows/nsd_windows_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  NdiWindowsPlayerPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("NdiWindowsPlayerPluginCApi"));
  NsdWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("NsdWindowsPluginCApi"));
}
