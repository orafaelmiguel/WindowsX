# Windows 10 Tweak Tool 

This project aims to automate the configuration and optimization of Windows 10 for maximum FPS and gaming performance using shell scripts.

The project is still under development and currently has the following features:

- CPU optimization at boot time
- Deactivation of useless services at boot time
- XMP status checking in the BIOS
- Deactivation of Windows hibernation

## Disabled Services List

Below is a list of unnecessary Windows services disabled by this optimization script.

| Service Name                           | Windows Name         | Function                                             | Why Disable?                                      |
|----------------------------------------|----------------------|------------------------------------------------------|--------------------------------------------------|
| **Connected User Experiences and Telemetry** | `DiagTrack`         | Collects user data for Microsoft analytics.        | Improves privacy and reduces CPU/RAM usage.     |
| **Push Notification Service**          | `dmwappushservice`  | Handles push notifications.                        | Not needed for gaming; consumes system resources. |
| **SysMain (Superfetch)**               | `SysMain`           | Speeds up frequently used apps (for HDDs).         | Can cause stutters in games; unnecessary for SSDs. |
| **Windows Search**                     | `WSearch`           | Indexes files for quick search.                    | Uses CPU/RAM constantly; not needed for gaming PCs. |
| **Xbox Game Save Service**             | `XblGameSave`       | Saves Xbox Live game progress.                     | Only useful for Xbox Game Pass users.           |
| **Xbox Live Networking Service**       | `XboxNetApiSvc`     | Manages Xbox Live network connections.             | Unnecessary unless playing Xbox multiplayer.    |
| **Touch Keyboard and Handwriting Panel** | `TabletInputService` | Provides handwriting recognition for touchscreens. | Useless unless using a touchscreen.             |
| **Windows Image Acquisition**          | `stisvc`           | Manages cameras and scanners.                      | Disable if you don’t use a scanner or webcam.  |
| **Retail Demo Service**                | `RetailDemo`       | Enables store demo mode.                           | Completely unnecessary for personal use.        |
| **Windows Maps Service**               | `MapsBroker`       | Manages map data for offline use.                  | Only needed for apps like Maps; frees RAM.      |
| **Geolocation Service**                | `lfsvc`           | Provides location data for applications.           | Saves memory and prevents tracking.            |
| **Remote Registry**                    | `RemoteRegistry`   | Allows remote editing of the Windows registry.     | Security risk; should be disabled.             |
| **Bluetooth Support Service**          | `bthserv`         | Handles Bluetooth devices.                         | Disable if you don't use Bluetooth peripherals. |
| **Fax Service**                        | `Fax`             | Supports sending and receiving faxes.              | Useless unless using a fax machine.            |
| **Print Spooler**                      | `Spooler`         | Manages print jobs.                                | Disable if you don’t use a printer.            |
| **Secondary Logon**                    | `seclogon`        | Allows users to run programs as another user.      | Not needed for gaming setups.                  |
| **Parental Controls**                  | `WPCSvc`          | Enforces parental control settings.                | Useless unless managing a child's PC.          |
| **Remote Desktop Services**            | `TermService`     | Allows remote access to the PC.                    | Disable if you don’t use Remote Desktop.       |

⚠ **Note:** If you rely on any of these services, you may want to enable them manually after running the optimization script.

## Installation

1 - To run scripts on Windows you'll have to set your Execution-Policy to Unrestricted, using the following command:

From an Administrator Powershell prompt:
```
Set-ExecutionPolicy Unrestricted
```

2 - Clone this rep
```
https://github.com/orafaelmiguel/Win10TweakTool.git
cd Win10TweakTool
```

3 - Install Git Bash in https://git-scm.com/downloads

4 - Run Git Bash as administrator in the cloned repository (or WSL btw):
```
chmod +x main.sh
sh main.sh
```

Or you can just download the executable file of the scripts :)

https://github.com/orafaelmiguel/Windows10-Gaming-Optimizer/releases/tag/v1.0.0

## Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/orafaelmiguel">
        <img src="https://avatars.githubusercontent.com/u/96322592?v=4" width="100px;" alt="orafaelmiguel"/>
        <br /><sub><b>orafaelmiguel</b></sub>
      </a>
    </td>
  </tr>
</table>

