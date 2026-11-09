# Windows Server 2022 on a Contabo VPS - Installation Guide

## Introduction

This guide provides step-by-step instructions for installing **Windows Server 2022** on a Contabo VPS. The script downloads the Windows Server 2022 and virtIO driver zip files, extracts them, and uses the ISO found inside each. Please be aware that you assume full responsibility for all risks associated with this installation.

## Prerequisites

- VNC Viewer application installed. Download it from [here](https://www.realvnc.com/en/connect/download/viewer/).
- A Contabo VPS
- Microsoft Remote Desktop for RDP connection to the machine.

## Steps for installation

### 0. (Only if reinstalling) Wipe the existing Windows installation

If Windows is already installed (for example Windows Server 2019 Evaluation), you do not need to delete anything by hand. Booting the VPS into the Rescue System and running the script below repartitions `/dev/sda` and erases the old installation completely. **All data on the VPS disk will be lost, so back up anything important first.**

### 1. Prepare the VPS for installation

- Log in to the Contabo user panel and navigate to the "Your services" section.
- On your VPS click the "Manage" button and select "Rescue System".
- Choose "Debian 10 - Live" from the "Rescue System Version" dropdown menu.
- Set a password and start the Rescue System. Wait until the VPS has rebooted into rescue mode.
- From the control panel go to "VPS control".
- Click the "Manage" button and select "VNC password".
- Set the VNC password. It must be 8 characters long, containing at least one uppercase and one lowercase character, and one number. Avoid using any special characters.

### 2. Connect to the VPS via SSH

- Open Terminal on MacOS or PuTTY on Windows.
- If you connected to this IP before, clear the old SSH host key: `ssh-keygen -R <MACHINE-IP>`
- Log in with the command `ssh root@<MACHINE-IP>` and enter your Rescue System password.
- Execute the following commands:
  - `apt install git -y`
  - `git clone https://github.com/epk2112/Windows-Server-Contabo-VPS-main.git`
  - `cd Windows-Server-Contabo-VPS-main`
  - `chmod +x windows-install.sh`
  - `./windows-install.sh`
  - The script downloads the Windows Server 2022 zip and the virtIO zip (several GB), so it takes longer than before (roughly 20-40 minutes depending on speed). It completes when the ssh session disconnects due to the machine rebooting.

> The `windows-install.sh` in this repository must be replaced with the modified version, which pulls the two zip files from the Hugging Face links and uses the `.iso` inside each one.

### 3. Connect to the VPS with VNC to install Windows

- Open your VNC app and create a new connection using the IP and PORT found on the VPS control page. Hover over "Manage" and click on "VNC Information"
- Upon connecting, you will see a screen as shown in the image. Press Enter.

  ![text](https://i.ibb.co/j8Ckb0x/windows-installer.png)

- Follow the on-screen prompts to install Windows.
- **When asked which edition to install, pick a Windows Server 2022 edition with "Desktop Experience" (GUI)**, otherwise you get a command-line-only server.
- Install the virtIO drivers as shown in the following images.
- Click on "Browse"

  ![text](https://i.ibb.co/x2S5brz/browser.png)

- From Boot select `virtio_drivers`

  ![text](https://i.ibb.co/MghHSxm/virtio.png)

- Select `amd64\2k22` (use `w10` only if `2k22` is not present) and click on "Ok"

  ![text](https://i.ibb.co/jTmb57J/w10.png)

- Click on "Next"

  ![text](https://i.ibb.co/LS3sq47/next.png)

- Click on "Custom: Install Windows Only (advanced)"

  ![text](https://i.ibb.co/X7swb6C/custom-install.png)

- For the installation, select the partition `Drive 0 Partition 1`

  ![text](https://i.ibb.co/mSq9KjR/select-partition.png)

- Choose the operating system and then click on "Next"

  ![text](https://i.ibb.co/2FF8W7b/os-select.png)

### 4. Install the Ethernet adapter for internet connection

- Open the `Device Manager`

  ![text](https://i.ibb.co/PxGQ9Rz/device-manager.png)

- Right-click on `Ethernet Controller` and select `Update Driver`

  ![text](https://i.ibb.co/Ycjf3b4/update-driver.png)

- Choose `Browse my computer for drivers`

  ![text](https://i.ibb.co/X7vht8v/browse-computer-drivers.png)

- Click on `Browse` and select the path `C:\sources\virtio`, and click "Next"

  ![text](https://i.ibb.co/7WJXyxW/driver-path.png)

- Click on `Install`

  ![text](https://i.ibb.co/0nqRzJG/install-driver.png)

### 5. Configure Your Contabo Static IP

Because the installation script bypasses the default setup, your server won't connect to the internet automatically until you assign its unique static IP configuration. This step is required for the internet connection to go live.

1. Log in to your Contabo Customer Control Panel in a web browser.
2. Navigate to the **Network** section in the left sidebar and click on **IP Assignment**.
3. Under the **Included IPs** tab, look at your primary listed IP address and hover over or click the information icon (ⓘ) to reveal your specific network credentials:
   - IP Address
   - Gateway
   - Netmask (Subnet Mask)
4. Switch back to your Windows Server VPS and locate the networking icon in the bottom right corner of your taskbar (the one indicating "Unidentified network / No Internet").
5. Right-click the icon and go to **Network & Internet Settings > Change adapter options**.
6. Right-click your Ethernet adapter, select **Properties**, then double-click **Internet Protocol Version 4 (TCP/IPv4)**.
7. Choose **Use the following IP address** and fill in the values exactly as you found them in your Contabo panel:
   - IP address: Your Contabo IP Address
   - Subnet mask: Your Contabo Netmask
   - Default gateway: Your Contabo Gateway
8. Select **Use the following DNS server addresses** and enter the following public DNS values to enable web browsing:
   - Preferred DNS server: `8.8.8.8`
   - Alternate DNS server: `1.1.1.1`
9. Click **OK** on both properties windows to save the configuration. Your internet connection will immediately go live!

### 6. Allow Remote Access Connection for RDP

- Search for `allow remote connections to this computer` and select the first option.

  ![text](https://i.ibb.co/Xb4hwQp/allow-remote.png)

- In the Remote Desktop section, click on `Show settings`

  ![text](https://i.ibb.co/kD4tN2P/show-settings.png)

- Choose `Allow remote connections to this computer`, click "Apply" and then "Ok"

  ![text](https://i.ibb.co/Rv0R5L1/allow-remote-connections.png)

- Now, connect remotely using your Remote Desktop Connection program with the credentials created during the Windows installation.

## Conclusions

Congratulations! You should now have a fully operational Windows Server 2022 installation on your Contabo VPS. Remember to proceed with these instructions at your own risk and ensure that all software and applications used are legal and compliant with the respective licenses.
