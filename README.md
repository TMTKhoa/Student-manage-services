# KhoaVeyonService

**English** | [Tiếng Việt](README.vi.md)

A single Windows batch file that adds classroom-control actions to [Veyon](https://veyon.io): force close apps, block the internet (LAN stays on), allow only chosen sites, block chosen apps, lock down Task Manager and Settings, and mute the speakers.

Each action is a command-line switch, so every one can be run on its own from Veyon's **Run program** feature.

```
C:\cmd\KhoaVeyonService.bat -blockall
```

> This is an independent script. It is not made by or affiliated with Veyon. It is **not** the paid *Internet Access Control* add-on from veyon.io; it is a free alternative built from Windows Firewall rules.

---

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Switches](#switches)
- [Excel list files](#excel-list-files)
- [Adding the actions to Veyon](#adding-the-actions-to-veyon)
- [How it works](#how-it-works)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Security notes](#security-notes)

---

## Features

| Feature | Switch |
|---|---|
| Force close all open apps | `-killapp` |
| Force close all apps except a list you choose | `-keepapp` |
| Block all internet, keep LAN and Veyon working | `-blockall` |
| Block the internet except sites listed in an Excel file | `-allowpage` |
| Allow all internet again | `-allowall` |
| Block apps or folders listed in an Excel file | `-blockapp` |
| Unblock those apps again | `-unblockapp` |
| Disable Task Manager and Settings/Control Panel | `-lockdown` |
| Enable them again | `-unlock` |
| Mute / unmute the speakers | `-mute`, `-unmute` |

Other points:

- One file, no compiled code, no third-party tools.
- Excel is **not** required on the PCs. The `.xlsx` lists are read directly.
- No admin password is stored anywhere in the script.
- Designed for a classroom of standard (non-admin) student accounts.

## Requirements

- Windows 10 or 11 on the student PCs (Windows PowerShell 5.1, built in).
- Veyon installed on the teacher PC and the clients. The actions are started with Veyon's **Run program** feature.
- **Windows Defender Firewall switched on**, with its service (`mpssvc`) running. The internet blocking works by adding firewall rules, so it does nothing if the firewall is off.
- Student accounts without administrator rights.
- The script must be installed in `C:\cmd` on every client.
- One-time admin approval on each PC (see [Installation](#installation)).

## Installation

Do this **once on each client PC**.

1. Create the folder `C:\cmd` and copy `KhoaVeyonService.bat` into it. Put your Excel list files there too (see [Excel list files](#excel-list-files)).
2. Run the setup as the PC's administrator. From Command Prompt:
   ```
   C:\cmd\KhoaVeyonService.bat -install
   ```
   Or double-click the file after opening it with `-install` as its argument. Windows asks for the admin name and password in the UAC window.
3. You should see `Install done`.

`-install` does two things:

- It creates one small Windows service per admin-level action (`KhoaVeyonService_blockall`, `_allowpage`, `_allowall`, `_blockapp`, `_unblockapp`). Standard users may **start** these services but not edit them.
- It makes `C:\cmd` read-only for normal users, so students cannot change the script or the lists.

### Firewall ports

If the Windows firewall was off before, make sure Veyon can still reach the clients:

```
netsh advfirewall firewall add rule name="Veyon Server" dir=in action=allow protocol=TCP localport=11100 profile=any
```

On the teacher PC, also allow port `11400` for Veyon's Demo feature. These are Veyon's default ports; use your own numbers if you changed them. No port forwarding is needed.

## Switches

| Switch | Needs install? | What it does |
|---|---|---|
| `-install` | - | One-time setup (needs admin). |
| `-uninstall` | - | Removes the services, firewall rules and app blocks. |
| `-killapp` | No | Force closes all apps in the logged-in user's session. Windows shell, Veyon, cmd and PowerShell are never closed. |
| `-keepapp` | No | Same as `-killapp`, but keeps the apps listed in `KeepAppList.xlsx`. |
| `-blockall` | Yes | Blocks all internet. LAN, localhost and Veyon keep working. Blocks IPv6 internet too. |
| `-allowpage` | Yes | Blocks the internet except the sites in `AllowPage.xlsx` (and the PC's DNS server). |
| `-allowall` | Yes | Removes the internet block. |
| `-blockapp` | Yes | Blocks the files or folders in `BlockAppList.xlsx` from running and closes copies that are already open. |
| `-unblockapp` | Yes | Removes those blocks. |
| `-lockdown` | No | Disables Task Manager and Settings/Control Panel for the logged-in user. |
| `-unlock` | No | Undoes `-lockdown`. `-unlockdown` also works. |
| `-mute` | No | Mutes the default speakers. |
| `-unmute` | No | Unmutes them. |

Run with no switch (or an unknown one) to print the usage line.

The internet block stays in place after a reboot until you run `-allowall`.

## Excel list files

Create these in `C:\cmd`. Use **column A of the first sheet**, one entry per row. A header row is fine (it is ignored if it does not look like a site or path). Only `.xlsx` files are read.

### `AllowPage.xlsx`

Sites to allow when you use `-allowpage`:

```
Site
wikipedia.org
vietjack.vn
```

`https://`, paths and `www.` are handled for you.

### `BlockAppList.xlsx`

Full paths of programs or folders to block with `-blockapp`. Wildcards and environment variables work:

```
Path
C:\Program Files\Google\Chrome\Application\chrome.exe
C:\Games\*.exe
C:\Users\Public\Games
```

Anything inside `C:\Windows`, the Veyon folder, `C:\cmd` and drive roots is skipped on purpose, so a typo cannot break the PC.

### `KeepAppList.xlsx`

Apps that `-keepapp` leaves open. Use a program name, with or without `.exe`, or a full path:

```
App
chrome
mathgame.exe
C:\Games\KidsLearning
```

### Changing the list folder

By default the lists are read from `C:\cmd\`. To use one shared copy for every PC, change `LISTDIR` near the top of the script to a network path (keep the trailing backslash). The share must be readable by the computer accounts (for the admin-level actions) and by the student accounts (for `-keepapp`).

Because `-install` makes `C:\cmd` read-only for normal users, you update the lists as an administrator.

## Adding the actions to Veyon

1. Open **Veyon Configurator** and go to **Programs & websites** (the name varies by version; in older versions it is under **Master**).
2. Add one entry per action. The command is the script path plus the switch:

| Name | Command |
|---|---|
| Close all apps | `C:\cmd\KhoaVeyonService.bat -killapp` |
| Close all except list | `C:\cmd\KhoaVeyonService.bat -keepapp` |
| Block internet | `C:\cmd\KhoaVeyonService.bat -blockall` |
| Allow listed sites only | `C:\cmd\KhoaVeyonService.bat -allowpage` |
| Allow internet | `C:\cmd\KhoaVeyonService.bat -allowall` |
| Block apps | `C:\cmd\KhoaVeyonService.bat -blockapp` |
| Unblock apps | `C:\cmd\KhoaVeyonService.bat -unblockapp` |
| Lockdown | `C:\cmd\KhoaVeyonService.bat -lockdown` |
| Unlock | `C:\cmd\KhoaVeyonService.bat -unlock` |
| Mute | `C:\cmd\KhoaVeyonService.bat -mute` |
| Unmute | `C:\cmd\KhoaVeyonService.bat -unmute` |

3. Click **Apply**.
4. In **Veyon Master**, select the student PCs, click **Run program**, and choose an entry.

## How it works

Veyon's **Run program** starts a command as the logged-in student, who has no admin rights. Changing the firewall needs admin rights, so the script uses two paths:

- **Admin-level actions** (`-blockall`, `-allowpage`, `-allowall`, `-blockapp`, `-unblockapp`): when started by a student, the script asks the matching SYSTEM service to run. The service starts the same script, which now has admin rights and does the work with PowerShell.
- **User-level actions** (`-killapp`, `-keepapp`, `-lockdown`, `-unlock`, `-mute`, `-unmute`): these run directly in the student's session and need no admin rights or service.

Details:

- **Internet blocking** adds two outbound firewall rules, `KhoaVeyonBlock` and `KhoaVeyonBlock6`. They block every address except private LAN ranges (`10.x`, `172.16-31.x`, `192.168.x`), localhost, link-local, multicast and broadcast.
- **`-allowpage`** looks up the IP addresses of each listed site and removes them from the blocked ranges. The PC's DNS servers are allowed as well.
- **`-blockapp`** adds a *deny Execute* permission for the Users group on each listed file or folder, and records the paths in `blocked.txt` so `-unblockapp` can undo it.
- **`-lockdown`** sets the `DisableTaskMgr` and `NoControlPanel` policies for the current user.
- **`-mute`** uses the Windows Core Audio API to mute the default output device.

The PowerShell code lives at the end of the `.bat` file, after the `#PS1START` marker. Do not put that text anywhere else in the file.

## Limitations

- **`-allowpage` works by IP address, not by domain.** Large sites that use many domains or CDNs (for example YouTube or Google) may load only partly, and IP addresses change over time. Run `-allowpage` again to refresh them. For reliable site filtering, use a DNS filter at your router.
- **A proxy server on your LAN defeats the block.** If the PCs reach the internet through a proxy with a LAN address, that traffic looks like LAN traffic and is allowed. Check with `netsh winhttp show proxy`.
- **Third-party firewalls and antivirus products** that manage the Windows firewall can override the rules.
- **Existing connections** may survive for a moment. Closing and reopening the browser makes the block visible immediately.
- **`-blockapp`** also affects administrators until you run `-unblockapp`. It does not block Microsoft Store (UWP) apps. A student can still copy a blocked program to another location.
- **`-lockdown` and `-mute`** apply only to the logged-in account. Students can still unmute with the keyboard volume keys.
- **Windows may log "service did not respond" (error 1053)** for the services. This is expected: the services are not real service programs, but the commands still run.
- Domain names and paths are processed from the first sheet only.

## Troubleshooting

**Nothing happens.**
Check the log. Admin-level actions write to `C:\cmd\KhoaVeyonService.log`; user-level actions write to `%TEMP%\KhoaVeyonService.log` of the logged-in student. The log records each action, missing list files and skipped paths.

**`Service not installed`.**
Run `-install` as the PC's administrator.

**The internet is still reachable after `-blockall`.**
Check, in this order:
1. The firewall is on: `netsh advfirewall show allprofiles state`
2. The rule exists: `netsh advfirewall firewall show rule name="KhoaVeyonBlock"`
3. There is no proxy: `netsh winhttp show proxy`
4. `ping 8.8.8.8` fails after the block, while `ping <teacher PC IP>` still works.

**A PC disappears from Veyon Master after the firewall was turned on.**
Add the incoming rule for port 11100 (see [Firewall ports](#firewall-ports)).

**`-mute` does nothing.**
Make sure the PC has an active output device. Check the log for the error text.

## Uninstall

Run as administrator on each PC:

```
C:\cmd\KhoaVeyonService.bat -uninstall
```

This removes the internet block, the app blocks and the services. You can then delete `C:\cmd`. `-lockdown` and `-mute` are per-user settings, so run `-unlock` and `-unmute` as the student if they are still active.

## Security notes

- The script contains **no passwords**. Admin rights are provided once, at install, through the Windows UAC prompt.
- The services run the script as SYSTEM, so anyone who can edit `C:\cmd` could run commands as SYSTEM. That is why `-install` makes the folder read-only for normal users. Keep students on standard accounts and do not give them write access to this folder.
- Tell your students and their parents that the classroom tools can restrict the PC, in line with your school's policy.

## License

Add a license of your choice (for example MIT) before publishing.
