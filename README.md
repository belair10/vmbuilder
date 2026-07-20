# vmbuilder

Ansible playbook that provisions a security-testing VM. It installs an offensive/analysis
toolkit, hardens logging (auditd + laurel), and customizes the terminal, tmux, browser, and
VS Code.

**Supported distros:** Parrot/Debian (`bookworm`) and Fedora. The playbook branches on
`ansible_os_family` and pulls distro-correct package names from per-role `vars/Debian.yml`
and `vars/RedHat.yml`.

> Install `ansible` from pip — the distro package is often older than what the roles need.

## Instructions

### Parrot / Debian
* Start with Parrot HTB Edition
* Install Ansible: `python3 -m pip install ansible`
* Clone and enter the repo
* `ansible-galaxy install -r requirements.yml`
* Make sure you have a sudo token: `sudo whoami`
* `ansible-playbook main.yml`

### Fedora
* Start with a fresh Fedora Workstation
* Install Ansible: `sudo dnf install ansible python3-pip` (or `python3 -m pip install --user ansible`)
* Clone and enter the repo
* `ansible-galaxy install -r requirements.yml`
* Make sure you have a sudo token: `sudo whoami`
* `ansible-playbook main.yml`

## Platform differences

| Area | Parrot / Debian | Fedora |
|------|-----------------|--------|
| Package manager | `apt` | `dnf` |
| Firewall SYN logging | ufw (`ufw.yml`) | **skipped** — Fedora ships firewalld |
| Docker repo | Debian apt repo | `docker-ce.repo` in `/etc/yum.repos.d` |
| Firefox policies path | `/usr/share/firefox-esr/distribution` | `/usr/lib64/firefox/distribution` |
| Docker published ports | work out of the box | firewalld reconfigured (masquerade + `8088/tcp` open) so container ports are reachable |

auditd + laurel logging, and everything else, run identically on both.

> **Testing under WSL2:** several pieces are auto-skipped on a WSL kernel because
> they can't work there, and run normally on bare-metal / a real Fedora VM:
> - **auditd + laurel** — the WSL2 kernel has no audit subsystem, so
>   `auditd.service` can't start (`configure-logging` skips them on WSL).
> - **firewalld** — not present in the WSL rootfs; `docker-firewalld.yml` skips
>   itself when `firewall-cmd` is absent.
> - **VS Code** — the `code` CLI refuses to run under WSL (it tells you to use
>   the Windows build + WSL extension), so the role is skipped when the kernel
>   is WSL.

## Installed tools

### System / packages (dnf/apt)
* **Recon/web:** nmap, hydra, snmp tools, whois, dnsutils/bind-utils, tcpdump, tshark/wireshark-cli
* **Utilities:** jq, exiftool, flameshot, vim, git, curl, wget, unzip, tar, gh (GitHub CLI)
* **Runtimes/build:** build tools (`build-essential` / `@development-tools`), default JDK, ruby + rubygems + dev headers, python3-pip, pipx, sqlite, mariadb client
* **Logging:** rsyslog, auditd/audit, gdb
* **Containers:** Docker CE (docker-ce, cli, containerd.io, buildx, compose plugins) — distro podman-docker shim removed first

### Go tools (`go install`)
* [kerbrute](https://github.com/ropnop/kerbrute)
* [pspy](https://github.com/dominicbreuker/pspy)
* [gobuster](https://github.com/OJ/gobuster)
* [ffuf](https://github.com/ffuf/ffuf)

### Python tools (pipx)
* [impacket](https://github.com/fortra/impacket)
* [NetExec](https://github.com/Pennyw0rth/NetExec)
* [Certipy](https://github.com/ly4k/Certipy) (`certipy-ad`)
* [BloodHound.py](https://github.com/dirkjanm/BloodHound.py) (`bloodhound-ce` branch)

### Ruby gems
* [evil-winrm](https://github.com/Hackplayers/evil-winrm) (+ winrm/gssapi/rubyntlm deps)

### GitHub repos / releases (cloned or downloaded to `/opt`)
* [sqlmap](https://github.com/sqlmapproject/sqlmap) (cloned to `/opt/sqlmap`, symlinked to `/usr/local/bin/sqlmap`)
* [SharpCollection](https://github.com/Flangvik/SharpCollection)
* [SecLists](https://github.com/danielmiessler/SecLists)
* [chisel](https://github.com/jpillora/chisel) (linux + windows)
* [PEASS-ng](https://github.com/carlospolop/PEASS-ng) (linpeas.sh, winPEASx64.exe)
* [chainsaw](https://github.com/WithSecureLabs/chainsaw)
* [BloodHound](https://github.com/BloodHoundAD/BloodHound) (linux release)

### Larger installers
* **BloodHound CE** — Docker Compose stack in `/opt/bloodhound/server` (port 8088). On first boot the playbook grabs the generated admin password and resets it via the API to `bloodhound_admin_password` (override in `roles/install-tools/defaults/main.yml` or with `-e`)
* **Metasploit Framework** — via the official omnibus installer
* **Burp Suite Community** — installed to `/opt/BurpSuiteCommunity`, symlinked to `/usr/local/bin/burpsuite`, with jython/jruby extensions and a CA cert helper
* **GEF** — GDB Enhanced Features extension
* **Go 1.24.1** — to `/usr/local/go`, symlinked into `/usr/local/bin`
* **laurel** — auditd plugin (v0.5.2) writing enriched logs to `/var/log/laurel`
* **VS Code** — via the `gantsign.visual-studio-code` role, with spell-checker, Python, PHP, Copilot, and Snyk extensions

## Off-Video Changes
* Mate-Terminal Colors, I show how to configure it here (https://www.youtube.com/watch?v=2y68gluYTcc). I just did the steps in that video on my old VM to backup the color scheme, then copied it to this repo.
* Evil-Winrm/Certipy/SharpCollection/CME/Impacket, will make a video for these soon
* Updated BurpSuite Activation. Later versions of ansible would hang if a shell script started a process that didn't die. Put a timeout on the java process
