import QtQuick
import Quickshell
import Quickshell.Io

// Headless: notices NVIDIA userspace drivers that installing Steam pulled
// onto a machine without an NVIDIA GPU and sends one notification per
// boot. Never removes anything itself: that needs root and a confirmed
// pacman transaction.
Item {
  id: root

  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string pluginDir: home + "/.config/omarchy/plugins/steam-nvidia-cleanup"
  readonly property string fixScript: pluginDir + "/bin/omarchy-steam-nvidia-cleanup"
  // Boot-scoped (tmpfs) markers: they only dedupe repeat notifications
  // within one boot. One marker per exit code.
  readonly property string stateDir: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy/indicators"
  readonly property string removableMarker: stateDir + "/steam-nvidia-cleanup-notified-removable"
  readonly property string blockedMarker: stateDir + "/steam-nvidia-cleanup-notified-blocked"

  function runCheck() {
    if (checkProcess.running) return
    checkProcess.running = true
  }

  function notifyOnce(marker, title, body) {
    notifyProcess.command = ["bash", "-c",
      "mkdir -p " + JSON.stringify(root.stateDir) + "; " +
      "[[ -f " + JSON.stringify(marker) + " ]] && exit 0; " +
      "touch " + JSON.stringify(marker) + "; " +
      "omarchy-notification-send -u normal " + JSON.stringify(title) + " " + JSON.stringify(body)
    ]
    notifyProcess.running = true
  }

  Process {
    id: checkProcess
    command: ["bash", root.fixScript, "--check", "--quiet"]
    onExited: function(exitCode) {
      if (exitCode === 1) {
        root.notifyOnce(root.removableMarker,
          "Unneeded NVIDIA drivers",
          "Steam pulled in nvidia-utils, but this machine has no NVIDIA GPU. Remove them: sudo " + root.fixScript)
      } else if (exitCode === 3) {
        root.notifyOnce(root.blockedMarker,
          "Steam has no matching Vulkan driver",
          "Steam only has the NVIDIA driver, but there's no NVIDIA GPU. Details: " + root.fixScript + " --check")
      }
    }
  }

  Process {
    id: notifyProcess
  }

  Timer {
    // Shortly after shell start, then hourly to catch a Steam install
    // mid-session. A check is a few pacman queries.
    interval: 20000
    running: true
    repeat: false
    onTriggered: root.runCheck()
  }

  Timer {
    interval: 3600000
    running: true
    repeat: true
    onTriggered: root.runCheck()
  }
}
