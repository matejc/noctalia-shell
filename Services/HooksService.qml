pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Modules.LockScreen

Singleton {
  id: root

  // Hook connections for automatic script execution
  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      executeDarkModeHook(Settings.data.colorSchemes.darkMode)
    }
  }

  Connections {
    target: WallpaperService
    function onWallpaperChanged(screenName, path) {
      executeWallpaperHook(path, screenName)
    }
  }

  Connections {
    target: PanelService.lockScreen
    function onUnlocked() {
      executeUnlockScreenHook()
    }
  }

  // Execute wallpaper change hook
  function executeWallpaperHook(wallpaperPath, screenName) {
    if (!Settings.data.hooks?.enabled) {
      return
    }

    const script = Settings.data.hooks?.wallpaperChange
    if (!script || script === "") {
      return
    }

    try {
      let command = script.replace(/\$1/g, wallpaperPath)
      command = command.replace(/\$2/g, screenName || "")
      Quickshell.execDetached(["sh", "-c", command])
      Logger.log("HooksService", `Executed wallpaper hook: ${command}`)
    } catch (e) {
      Logger.error("HooksService", `Failed to execute wallpaper hook: ${e}`)
    }
  }

  // Execute dark mode change hook
  function executeDarkModeHook(isDarkMode) {
    if (!Settings.data.hooks?.enabled) {
      return
    }

    const script = Settings.data.hooks?.darkModeChange
    if (!script || script === "") {
      return
    }

    try {
      const command = script.replace(/\$1/g, isDarkMode ? "true" : "false")
      Quickshell.execDetached(["sh", "-c", command])
      Logger.log("HooksService", `Executed dark mode hook: ${command}`)
    } catch (e) {
      Logger.error("HooksService", `Failed to execute dark mode hook: ${e}`)
    }
  }

  // Execute unlock screen hook
  function executeUnlockScreenHook() {
    if (!Settings.data.hooks?.enabled) {
      return
    }

    const script = Settings.data.hooks?.unlockScreenChange
    if (!script || script === "") {
      return
    }

    try {
      const command = script
      Quickshell.execDetached(["sh", "-c", command])
      Logger.log("HooksService", `Executed unlock screen hook: ${command}`)
    } catch (e) {
      Logger.error("HooksService", `Failed to execute unlock screen hook: ${e}`)
    }
  }

  // Initialize the service
  function init() {
    Logger.log("HooksService", "Service initialized")
  }
}
