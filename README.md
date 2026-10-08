# DJA0231 Wi-Fi backhaul

This turns a rooted Telstra DJA0231 into a Wi-Fi booster. It joins the main modem over Wi-Fi and keeps its own 2.4 GHz and 5 GHz networks for nearby clients. It is not the EasyMesh `bridged-booster` script. That one expects a cable back to the main modem. This one uses Wi-Fi as the backhaul.

The upstream network name and password are not in this download. After the booster boots, choose that network in the Wi-Fi Backhaul card.

## Acknowledgements

A huge thank you to [seud0nym](https://github.com/seud0nym/tch-gui-unhide) for the assistance and guidance he has generously provided me over the years, and to the wider Technicolor modding community for the work that makes projects like this possible.

The ability to root, unlock and modify these devices is thanks to the countless hours others have spent researching, documenting and developing tools for Technicolor hardware.

This project builds on that work by exploring another practical use for rooted Telstra Gen 2 hardware — repurposing a spare device as a wireless booster using Wi-Fi backhaul. It is not intended to replace or take credit for the work that made these modifications possible.

Without projects such as [tch-gui-unhide](https://github.com/seud0nym/tch-gui-unhide), this project simply wouldn't exist.

If you're new to rooting or modifying these devices, I strongly encourage you to visit [seud0nym's GitHub repository](https://github.com/seud0nym/tch-gui-unhide) to learn more about the rooting and unlocking process, as well as the work that has gone into making these devices accessible for further modification.

## Download and install

Before installing Wi-Fi Backhaul, you must run `pre-booster`. This prepares the rooted Telstra DJA0231 by assigning it an IP address on the same network as your main modem.

**Important:** Make sure the IP address you choose is not already being used by another device.

For example, if your main modem uses `192.168.100.1`, you could assign the booster `192.168.100.4`, provided that address is available.

### Step 1: Prepare the booster

There are two ways to configure the booster's network address.

**Option 1: Manual IP configuration**

Download and run `pre-booster`, specifying the IP address you want the booster to use.

```bash
curl -skLo pre-booster https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/pre-booster
chmod +x pre-booster
./pre-booster -i 192.168.100.4 -y
```

Depending on your existing network configuration, you may need to reconnect your LAN or WAN cables before accessing the booster at its new address.

**Option 2: Configure using the main modem (recommended)**

Connect the booster's WAN port to a LAN port on your main modem using an Ethernet cable.

This method allows `pre-booster` to obtain network information from the main modem through DHCP before configuring the booster with an available IP address.

```bash
./pre-booster -w -i 192.168.100.4 -y
```

The WAN connection remains active throughout the installation, allowing you to continue accessing the booster over the Ethernet cable.

Once complete, open the booster's new address in your browser:

`http://192.168.100.4/`

Confirm that the web interface loads before proceeding.

For more information about `-i`, `-w` and `-y`, refer to the **Installer options** section below.

### Step 2: Install Wi-Fi Backhaul

Once `pre-booster` has completed successfully, download and run the main Wi-Fi Backhaul installer.

```bash
curl -skLo wifi-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul
chmod +x wifi-backhaul
./wifi-backhaul -y
```

The installer retains the IP address configured by `pre-booster` and makes the necessary changes to prepare the device for wireless backhaul operation.

During installation, the script will:

- Disable unnecessary services, including WPS and UPnP.
- Remove unused service cards from the web interface.
- Reconfigure the WAN port to function as an additional LAN port.
- Restart the necessary network services.
- Temporarily configure a small subnet with DHCP enabled, providing two addresses for local access (one for Ethernet and one for Wi-Fi).

**Important:** Your connection to the booster may temporarily drop while these changes are applied. Allow a couple of minutes for the network services to restart.

Once a Wi-Fi backhaul connection has been successfully established, the booster automatically restores the `/24` subnet and disables its DHCP server, allowing the main modem to manage IP address allocation.

### Step 3: Connect the Wi-Fi backhaul

After installation, open the booster's web interface using the IP address configured earlier.

For example:

`http://192.168.100.4/`

Locate the **Wi-Fi Backhaul** card and select the wireless network you want the booster to connect to.

Enter the network password and establish the connection.

Once the wireless backhaul is connected and working:

1. Confirm that the booster can communicate with the main modem.
2. Disconnect the Ethernet cable connecting the booster to the main modem.
3. Move the booster to its intended location.
4. Reconnect to the booster's web interface to confirm that the wireless backhaul is still operational.

Your rooted Telstra DJA0231 should now be operating as a wireless booster, using Wi-Fi for its connection to the main modem while providing its own 2.4 GHz and 5 GHz wireless networks for nearby devices.

## Fresh setup (optional)

If you're starting with a freshly rooted Telstra DJA0231 or want to begin with a clean configuration, the following steps will prepare the modem for Wi-Fi Backhaul.

**Important:** These steps are intended for an already rooted device. Do not perform a factory reset unless you are confident your firmware supports retaining root access.

### Step 1: Reset to factory defaults (optional)

If you want to start with a clean configuration while retaining root access, run:

```bash
cp -p reset-to-factory-defaults-with-root /tmp
cd /tmp
sh reset-to-factory-defaults-with-root -c -y
```

This resets the modem's configuration while preserving root access.

### Step 2: Install Technicolor modifications

Download and run the `tch-gui-unhide` installer developed by [seud0nym](https://github.com/seud0nym/tch-gui-unhide):

```bash
curl -skL https://raw.githubusercontent.com/seud0nym/tch-gui-unhide/master/get | sh
```

Once installed, run:

```bash
./de-telstra -A -y
./tch-gui-unhide -hn -dy -Cs -tc -a5 -y
```

These commands remove unnecessary Telstra-specific settings and configure the web interface for use with Wi-Fi Backhaul.

**What does `de-telstra -A` do?**

The `-A` option applies several changes, including:

- Setting the hostname to the modem model.
- Setting the domain name to `gateway`.
- Disabling WPS and UPnP.
- Disabling sharing services and NAT helpers.

Wi-Fi Backhaul also removes unused services from the web interface during installation.

These changes do not modify EasyMesh or DumaOS.

**Optional: Customise the hostname**

If you'd prefer to give your booster a custom hostname and domain name, run:

```bash
./de-telstra -h DJA0231-Booster -d DJA0231-Booster -y
```

Replace `DJA0231-Booster` with your preferred name.

### Step 3: Customise the web interface

The `tch-gui-unhide` command above includes several options to simplify the web interface.

| Option | Description |
|---|---|
| `-hn` | Sets the browser title to the modem's hostname. |
| `-dy` | Allows access to the web interface without a password. |
| `-Cs` | Displays a single summary chart instead of separate CPU, RAM, Backhaul Download and Backhaul Upload cards. |
| `-tc` | Enables the classic theme. |
| `-a5` | Displays five cards across the web interface. |
| `-y` | Automatically confirms prompts. |

The Wi-Fi Backhaul installer preserves the summary chart configuration. If `-Cs` was not used, the individual monitoring cards will remain visible.

**Security note:** The `-dy` option disables password protection for the web interface. Only use this on a trusted network.

### Step 4: Install Wi-Fi Backhaul

With the modem reset and the Technicolor modifications installed, you're ready to configure Wi-Fi Backhaul.

Follow the instructions in the **Download and install** section above to:

1. Run `pre-booster` and assign the booster an available IP address on your main network.
2. Install the `wifi-backhaul` script.
3. Open the Wi-Fi Backhaul card and connect to your main modem's wireless network.
4. Confirm the wireless connection is working before disconnecting the Ethernet cable and relocating the booster.

The backhaul connection uses DHCP by default. If you prefer a static IP address, this can be configured directly through the Wi-Fi Backhaul card.

**Re-running the installer:** Running `./wifi-backhaul` again preserves any previously saved upstream Wi-Fi network and backhaul IP configuration.

## How to use it

By default, running `./wifi-backhaul -y` configures the booster to connect to a visible Wi-Fi network. It does not automatically copy the main modem's Wi-Fi settings or enable the optional Wi-Fi Booster card.

Additional options are available if you want to mirror your main modem's Wi-Fi settings or connect directly to its hidden backhaul network.

**Important:** If Wi-Fi Backhaul is already installed, include `-U` when running the installer again. This preserves the booster's LAN IP address, saved Wi-Fi networks and backhaul IP configuration.

Refresh your browser after making changes.

### 1. Connect to your main modem

Open the Wi-Fi Backhaul card in the booster's web interface.

Click **Scan** to discover available wireless networks.

Select your main modem's visible Wi-Fi network (for example, `Telstra1B279D`).

Enter the Wi-Fi password configured on your main modem.

Connect and wait for the wireless backhaul to establish a connection.

**Note:** The Wi-Fi network name (SSID) and password are different. Make sure you enter the actual Wi-Fi password.

#### Managing saved networks

Once connected, Wi-Fi Backhaul remembers the network name and password, making it easier to reconnect later.

- **Reconnect:** Reconnects using the previously saved password.
- **Disconnect:** Disconnects from the current network without deleting its saved details.
- **Forget Network:** Removes the saved network and its password.

Previously connected networks remain listed under Available Networks, even after connecting to another network.

The active connection appears under Current Backhaul, where you can disconnect or forget it.

### 2. Mirror your main modem's Wi-Fi settings

Wi-Fi Backhaul can automatically copy your main modem's 2.4 GHz and 5 GHz Wi-Fi names and passwords to the booster's own wireless networks.

This allows the booster to broadcast the same network names as your main modem, making it easier for devices to connect as you move around your home.

Two options are available.

#### Option A: Copy Wi-Fi settings once (`-s`)

```bash
./wifi-backhaul -U -s -y
```

Copies the main modem's Wi-Fi settings once. Run the command again whenever you want to update them.

#### Option B: Automatically synchronise Wi-Fi settings (`-S`)

```bash
./wifi-backhaul -U -S -y
```

Copies the settings immediately and creates a scheduled task to check for changes every hour.

Both options:

- Copy the 2.4 GHz and 5 GHz SSIDs and passwords.
- Enable band steering on the booster if it is enabled on the main modem, using the same SSID across both bands.
- Leave guest Wi-Fi networks unchanged.
- Preserve the existing wireless backhaul connection.
- Make no changes if the main modem is not connected.

#### Automatic synchronisation

When using `-S`, the booster checks the main modem's Wi-Fi settings every hour.

If the SSIDs, passwords or band steering configuration have changed, the booster updates its settings to match. If everything already matches, no changes are made.

You can view or modify this schedule under Management → Scheduled Tasks. The command is `/root/dja-backhaul/sync-upstream-ssid`. It starts once an hour. Set Hour to `*/6`, and leave Minute at `0`, to run every 6 hours (12:00am, 6:00am, 12:00pm and 6:00pm). Leave the command as it is. The next `./wifi-backhaul -U -S -y` keeps the time you set.

Deleting the task, or turning Enabled off, disables automatic synchronisation. `./wifi-backhaul -U -y` without `-S` removes the row.

#### Alternative: Copy through the web interface

You can also copy the settings directly from the Access Point configuration page.

Under Protected Management Frames, locate **Mirror Main Wi-Fi SSID** and select **Copy**.

This performs the same one-time synchronisation as `-s`.

**Important notes:**

- The wireless backhaul must already be connected to the main modem before copying settings.
- The booster's 5 GHz radio must operate on the same channel as the main modem because it is also used for the wireless backhaul.
- The 2.4 GHz radio can operate on a different channel.
- SSIDs are copied exactly as configured on the main modem, without adding a suffix or additional characters.

### 3. Enable the Wi-Fi Booster card

Telstra Gen 2 modems also have a dedicated hidden wireless backhaul network used by compatible boosters.

Wi-Fi Backhaul includes an optional Wi-Fi Booster card that can retrieve the information required to connect to this hidden network.

To enable the card, run:

```bash
./wifi-backhaul -U -b -y
```

Refresh the web interface once the installer has finished.

The card is not enabled during a standard installation. However, once enabled using `-b`, it remains available when running `./wifi-backhaul -U -y` again.

#### Connecting to the hidden backhaul network

Before proceeding, connect the booster to your main modem's visible Telstra Wi-Fi network.

Then:

1. Open the Wi-Fi Booster card.
2. Select **Collect main backhaul**.
3. Allow the card to retrieve the hidden backhaul configuration.
4. Open Wi-Fi Backhaul and locate the network listed as **Main backhaul**.
5. Select **Connect** to establish the connection.

The collection process retrieves three important values:

- **Backhaul SSID:** The hidden network name obtained from the main modem's Wi-Fi Boosters page.
- **Backhaul password:** The password associated with the hidden backhaul radio, which is different from the visible Wi-Fi network's password.
- **Beacon address (BSSID):** The correct wireless address identified through scanning. This is important because the MAC address displayed on the main modem's wireless configuration page belongs to a different radio.

These values are saved for future connections. The password is not displayed in the card.

The same information is stored by a working Telstra booster under `/root/dja-backhaul/`.

This functionality has been identified on firmware `20.3.c.0389`.

**Troubleshooting:** The hidden backhaul uses the main modem's 5 GHz channel. If connecting to it causes internet connectivity to drop, use Forget Network on that entry and reconnect to the visible Telstra Wi-Fi network.

### 4. Mirror Wi-Fi settings and switch to the hidden backhaul

If you want to mirror the main modem's Wi-Fi settings and connect to its hidden backhaul network, both features can be combined into a single command.

#### One-time Wi-Fi synchronisation with hidden backhaul (`-bs`)

```bash
./wifi-backhaul -U -bs -y
```

This will:

- Enable the Wi-Fi Booster card.
- Copy the main modem's 2.4 GHz and 5 GHz SSIDs and passwords.
- Match the main modem's band steering configuration.
- Attempt to switch the wireless backhaul connection to the hidden network.

#### Automatic Wi-Fi synchronisation with hidden backhaul (`-bS`)

```bash
./wifi-backhaul -U -bS -y
```

Performs the same initial configuration but also creates an hourly scheduled task to keep the booster's Wi-Fi settings synchronised with the main modem.

**Before running either command:** Connect to the visible Telstra Wi-Fi network first. This allows the script to retrieve the information required for the hidden backhaul connection.

If the hidden network's beacon has not yet appeared in a scan, the switch will wait until it becomes available.

If the hidden backhaul connection causes internet connectivity to drop, forget that network in the Wi-Fi Backhaul card and reconnect to the visible Telstra network. You may need to enter its password again if the saved credentials were replaced.

### 5. Updating Wi-Fi Backhaul

To download the latest version of Wi-Fi Backhaul, run:

```bash
curl -skLo wifi-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul
chmod +x wifi-backhaul
./wifi-backhaul -U -y
```

Using `-U` preserves the existing configuration, including:

- The booster's LAN IP address.
- Previously saved Wi-Fi networks.
- The configured wireless backhaul IP address.

#### Reapplying tch-gui-unhide

If you need to reapply the Technicolor web interface modifications, run:

```bash
./tch-gui-unhide -dy -y
```

This rebuilds the web interface while retaining the Wi-Fi Backhaul and Wi-Fi Booster cards.

Unused dashboard cards, including Content Sharing, Mobile, Printer Sharing, Parental Controls and Relay Setup, remain hidden. Messages about missing cards from removed services are also suppressed.

**Important:** If updating tch-gui-unhide using its `get` installer replaces the contents of `/root/tch-gui-unhide`, run the Wi-Fi Backhaul installer again:

```bash
./wifi-backhaul -U -y
```

This restores the Wi-Fi Backhaul modifications without resetting your saved network configuration.

### Command reference

| Command option | Purpose |
| --- | --- |
| `-U` | Preserve existing network configuration when rerunning the installer |
| `-s` | Copy the main modem's Wi-Fi settings once |
| `-S` | Copy settings and enable hourly synchronisation |
| `-b` | Enable the Wi-Fi Booster card |
| `-bs` | Copy settings once and attempt hidden backhaul |
| `-bS` | Hidden backhaul with hourly Wi-Fi synchronisation |
| `-y` | Automatically confirm installer prompts |

## Read the hidden network on the main modem

If you prefer to retrieve the hidden backhaul network details directly from your main Telstra modem, you can use the `main-backhaul` script.

This script collects the hidden backhaul network name (SSID), password and beacon address (BSSID) required for the booster to establish a connection.

### Step 1: Run the script on the main modem

Connect to your rooted main Telstra modem using SSH, then download and run:

```bash
curl -skLo main-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/main-backhaul
chmod +x main-backhaul
./main-backhaul
```

The script saves the collected information to `/tmp/dja-main-backhaul`.

For security, the backhaul password is saved to a file rather than displayed in the terminal.

### Step 2: Transfer the files to the booster

Copy the `/tmp/dja-main-backhaul` directory from the main modem to your booster, including the password file.

Once the files have been transferred, run the following command on the booster:

```bash
./take-main-backhaul /tmp/dja-main-backhaul
```

### Step 3: Connect to the hidden backhaul

Open the booster's web interface and navigate to the Wi-Fi Backhaul card.

The imported network will appear as **Main backhaul**.

Select **Connect** to establish the wireless backhaul connection using the saved credentials.

You do not need to manually enter the hidden network's password.

## Update an existing booster

Wi-Fi Backhaul can be updated without losing your existing network configuration.

To download and install the latest version, run:

```bash
./wifi-backhaul -U -y
```

The `-U` option downloads the latest installer and applies the update while preserving:

- The upstream Wi-Fi network and saved credentials.
- The saved wireless radio lock.
- The backhaul IP address.
- The booster's LAN IP address.
- The configured USB backup schedule.

The wireless backhaul connection remains active during the update.

Once complete, refresh your browser to load the updated web interface.

### First-time update

If you haven't previously downloaded the installer, run:

```bash
curl -skLo wifi-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul
chmod +x wifi-backhaul
./wifi-backhaul -U -y
```

For future updates, you can simply run:

```bash
/root/wifi-backhaul -U -y
```

This automatically downloads and applies the latest version from GitHub.

## Keeping the pages after a tch-gui-unhide upgrade

If you're updating tch-gui-unhide, use:

```bash
./tch-gui-unhide -U -y
```

This updates the Technicolor web interface while restoring the Wi-Fi Backhaul modifications and keeping the booster-specific pages available.

Unnecessary dashboard cards remain removed, including Content Sharing, Mobile, Printer Sharing, Parental Controls and Relay Setup.

The update also suppresses `No such file or directory` messages associated with these removed cards.

**Important:** If you reinstall tch-gui-unhide using its original `get` installer, the contents of `/root/tch-gui-unhide` may be replaced.

If this happens, run:

```bash
./wifi-backhaul -U -y
```

This reapplies the Wi-Fi Backhaul modifications and ensures they are retained during future tch-gui-unhide upgrades.

## What the booster does

The booster stays on the main modem's LAN. One 5 GHz interface is only the link back to the main modem. The local 2.4 GHz and local 5 GHz names are separate and are not renamed to the upstream network.

- The physical Wi-Fi button turns the local 2.4 GHz and local 5 GHz radios off and on. It does not drop the backhaul, and it does not turn the Online light red.
- Band steering is still available. When it is on, the two local radios share one Wi-Fi name. When it is off, they keep separate names.
- DNS is read from the main modem and shown on the booster. The DNS fields are not edited here. If the main modem's DNS changes, the booster picks that up.
- The old WAN port is a normal LAN port.
- Guest Wi-Fi is not shown. Turning those names on here would not give clients internet. Guest Wi-Fi on the main modem still works for clients in range of the main modem.
- Telephony and WireGuard are removed. Filling in phone details, or changing the WireGuard port, does not make either one carry this booster. Phone service stays on the main modem. A VPN for the house belongs on the main modem.

## Home page

The basic Home view is the network map.

- Joining lines run from the booster to Wi-Fi, Ethernet, and USB, in the same layout as the main modem.
- The USB column lists a plugged-in stick: product name, manufacturer, and port. The internal LTE-A module is not listed.
- DECT is not shown.
- The Wi-Fi details on the left are the local networks, not the upstream network.

## Dashboard cards

The **Advanced** dashboard has been simplified to focus on the features relevant to a wireless booster. Unnecessary services and cards have been removed or hidden, while the remaining cards provide access to network settings, connection monitoring and management.

### Removed and hidden cards

The following changes are made to the dashboard:

- **Broadband:** Hidden, as the booster connects to the main modem over Wi-Fi rather than using its own broadband connection.
- **Removed services:** Mobile, DNS, Firewall, xDSL, NAT Helpers and Relay Setup are removed from the dashboard and Management. The Mobile service is also disabled.
- **Hidden cards:** Eco Settings, Diagnostics, Packages, System Extras and Devices are hidden by default but can be re-enabled through Management.
- **Device Security:** Removed from the dashboard.
- **Diagnostics:** The TCP Dump tab is removed.

### Available dashboard cards

- **Internet Access:** Displays the upstream Wi-Fi network, signal strength and connection rate. Backhaul download and upload statistics are shown in the corner of the card.
- **Wi-Fi Backhaul:** Displays the active upstream connection, including its SSID, signal strength, connection rate, channel, channel width and uptime. It also allows you to scan for, connect to and manage wireless networks.
- **Wi-Fi Booster:** An optional card for retrieving the main modem's hidden backhaul network information. It is only available when the installer has been run with `-b`.
- **Wi-Fi:** Displays the booster's local 2.4 GHz and 5 GHz wireless networks, with each band clearly separated.
- **Local Network:** Displays the booster's LAN IP address, along with the backhaul IP address and gateway when connected.
- **USB Backup:** Provides access to USB configuration backups and restoration.
- **Management:** Allows you to view, enable or disable dashboard cards. The Wi-Fi Backhaul card has its own switch, and USB Backup is labelled **USB**.

### Managing Wi-Fi Backhaul connections

The **Wi-Fi Backhaul** card provides two sections: **Current Backhaul** and **Available Networks**.

**Current Backhaul** displays the active wireless connection and provides two options:

- **Disconnect:** Disconnects from the current network while retaining its saved credentials.
- **Forget Network:** Disconnects and removes the saved network and password.

**Available Networks** displays networks discovered during scanning, including those previously connected to.

Saved networks are marked **Saved** and provide the following options:

- **Reconnect:** Reconnects using the stored password.
- **Forget Network:** Removes the saved network and its credentials.

When connecting to a network, the booster also saves a lock to the wireless radio (BSSID) it joined.

- Disconnecting removes the active radio lock.
- Connecting to a different network replaces the previous lock with the newly connected radio.
- Reconnecting updates the saved radio lock to match the connection.

This helps the booster reconnect to the intended wireless access point.

**Important:** When connecting to a network, enter the Wi-Fi password configured on the main modem. The network name (SSID) cannot be used as the password.

### System monitoring cards

The dashboard's monitoring layout depends on how `tch-gui-unhide` was configured.

By default, the following cards are available:

- CPU
- RAM
- Backhaul Download
- Backhaul Upload

If `./tch-gui-unhide -Cs` was used, these four cards are replaced with a single summary chart.

The Wi-Fi Backhaul installer respects this configuration and does not restore the individual cards when the summary chart is enabled.

## Local Network page

The **Local Network** page has been adjusted to reflect the booster's role on the main modem's network.

- **Local Network Subnet:** Displays the configured subnet but cannot be edited.
- **IPv6:** Displays a read-only On or Off status based on router advertisements received from the main modem. This setting does not enable or disable IPv6 on the booster.
- **Local Domain Name:** Can be changed to suit your network.
- **IPv4 Address:** Allows you to change the booster's LAN IP address. Saving a new address updates the booster's network configuration.
- **Guest interfaces:** Hidden, as guest networking is not supported on the booster.

## Wi-Fi page

The **Wi-Fi** page manages the booster's local wireless networks independently of its upstream backhaul connection.

- **Wireless bands:** Separate tabs are available for the local 2.4 GHz and 5 GHz networks.
- **Mirror Main Wi-Fi SSID:** Located under **Protected Management Frames**, the **Copy** button retrieves the main modem's Wi-Fi names and passwords and applies them to the booster's local networks. This is a one-time synchronisation, equivalent to using `-s`.
- **Guest Wi-Fi:** Guest network names are hidden.
- **Wireless Control and Wifi Nurse:** These options are removed from the interface.
- **Backhaul independence:** Changing the local Wi-Fi name or password does not modify the upstream backhaul connection.

**Note:** Wi-Fi mirroring requires an active connection to the main modem. If the main modem is not connected, no settings are changed.

## USB backup

The **USB Backup** card provides a convenient way to back up and restore the booster's configuration directly from the web interface.

The original backup and restore commands remain available through SSH, with the card providing an easier way to access the same functionality.

### Available options

- **Schedule daily backup:** Enables an automatic daily backup of the configuration, environment and overlay. Once enabled, the button changes to **Turn off daily backup**, allowing you to remove the scheduled task. The same row is under Management → Scheduled Tasks, command `/root/mtd-backup -d backups -ceoy`. Minute and Hour there are the backup time. Turning Enabled off, or deleting the row, turns the daily backup off.
- **Hour and Minute:** Allows you to customise when the daily backup runs. For example, setting Hour to `4` and Minute to `8` schedules the backup for 4:08 AM.
- **Backup now:** Immediately creates a backup using the same process as the scheduled task.
- **Restore and reboot:** Restores the saved configuration and restarts the booster. A confirmation prompt is displayed before proceeding.

**Important:** A USB storage device must be connected before using the backup or restore functions. The card displays whether a USB device is detected.

### Restore command compatibility

On this firmware, the command `mtd-restore -fsr` does not work because `-f` is not a supported option.

Instead, the **Restore and reboot** button uses:

```bash
mtd-restore -sr
```

This restores the saved configuration and reboots the booster.

## Installer options

The following options are available for configuring, updating and managing Wi-Fi Backhaul.

### pre-booster

The `pre-booster` script prepares the modem's network configuration before installing Wi-Fi Backhaul.

Example:

```bash
./pre-booster -w -i 192.168.100.4 -y
```

| Option | Description |
|---|---|
| `-i` | **Required.** Specifies the booster's LAN IP address. Choose an unused address on the main modem's network. |
| `-w` | Enables wired setup using the WAN port connected to the main modem's LAN port. Obtains network information through DHCP, verifies the selected IP address is available and on the correct network, then saves it while maintaining the WAN session. |
| `-y` | Automatically confirms prompts without asking for confirmation. |

**Without `-w`:**

```bash
./pre-booster -i 192.168.100.4 -y
```

The script changes the booster's LAN IP address and restarts networking. DHCP remains enabled.

**With `-w`:**

Connect the booster's WAN port to a LAN port on the main modem before running the script.

Once `pre-booster` has completed, install Wi-Fi Backhaul:

```bash
./wifi-backhaul -y
```

The network connection may temporarily drop during installation. Once networking has restarted, you can access the booster at its configured IP address using the same Ethernet cable.

Connect the wireless backhaul through the web interface before disconnecting the cable and relocating the booster.

### wifi-backhaul

The main installer configures the device for wireless backhaul operation and provides optional features for Wi-Fi synchronisation and hidden backhaul connectivity.

Standard installation:

```bash
./wifi-backhaul -y
```

| Option | Description |
|---|---|
| `-i` | Not required. The LAN address is already configured by `pre-booster`. |
| `-U` | Updates an existing installation while preserving saved network settings. |
| `-b` | Enables the optional Wi-Fi Booster card for retrieving the main modem's hidden backhaul information. |
| `-s` | Copies the main modem's 2.4 GHz and 5 GHz SSIDs and passwords once, including enabling band steering when it is enabled on the main modem. |
| `-S` | Copies Wi-Fi settings immediately and creates a scheduled task to check for changes every hour. Set Hour to `*/6` under Management → Scheduled Tasks to run every 6 hours. |
| `-bs` | Combines `-b` and `-s`, enabling the Wi-Fi Booster card, copying Wi-Fi settings once and attempting to connect to the hidden backhaul network. |
| `-bS` | Combines hidden backhaul functionality with automatic hourly Wi-Fi synchronisation. |
| `-y` | Automatically confirms installer prompts. |
| `-t` | Checks the packaged files and exits without proceeding with installation. |

### Additional notes

- **Preserving configuration:** Running `./wifi-backhaul -U -y` retains existing network settings, including the Wi-Fi Booster card if it was previously enabled.
- **Wi-Fi synchronisation:** The `-s` and `-S` options require an active connection to the main modem. If no connection is available, the Wi-Fi settings remain unchanged.
- **Scheduled synchronisation:** The hourly task created by `-S` can be viewed and adjusted under **Management → Scheduled Tasks**.
- **Hidden backhaul:** The `-b` option enables collection of the hidden network's SSID, password and beacon address.
- **Wireless channel:** The booster's 5 GHz backhaul uses the same channel as the main modem.

For detailed instructions and examples of each configuration option, refer to the **How to use it** section above.

### restore-fresh-root

The `restore-fresh-root` script removes Wi-Fi Backhaul and returns the modem to a clean, freshly rooted configuration while preserving root access.

This is useful if you want to repurpose the modem, start again or remove Wi-Fi Backhaul entirely.

**Available commands:**

```bash
./restore-fresh-root -y
./restore-fresh-root -I 192.168.100.2 -y
```

| Option | Description |
|---|---|
| `-I` | Sets a specific LAN IP address after the reset. If omitted, the factory LAN address is used unless `-i` is specified. |
| `-i` | Preserves the booster's current LAN IP address. Cannot be used together with `-I`. |
| `-y` | Automatically confirms prompts without asking for confirmation. |

For detailed instructions, refer to the **Put the booster back** section below.

## Put the booster back

If you no longer want to use your Telstra DJA0231 as a wireless booster, `restore-fresh-root` can return it to a clean, freshly rooted configuration.

The process follows the same general approach documented in the [tch-gui-unhide wiki](https://github.com/seud0nym/tch-gui-unhide/wiki).

**Important:** This process removes the Wi-Fi Backhaul configuration, including saved upstream networks and booster-specific web interface modifications.

Root access is preserved, but the root password is reset to `root`. **You should change this password immediately after restoring the modem.**

This is not a return to completely stock Telstra firmware. The modem remains rooted, with `de-telstra` and a clean installation of `tch-gui-unhide`.

This process is also different from **USB Backup**, which restores a previously saved booster configuration.

### Running restore-fresh-root

The Wi-Fi Backhaul installer automatically installs `restore-fresh-root` in `/root`.

Connect to the booster using SSH and run the script from that directory.

**You do not need to manually reset the modem first.** The script handles the factory reset, network configuration and reinstallation of the required Technicolor modifications automatically.

### Option 1: Restore using the factory LAN address

To remove Wi-Fi Backhaul and return the modem to its factory LAN address, run:

```bash
./restore-fresh-root -y
```

The script automatically performs three steps:

1. **Reset the modem while preserving root access.** Copies `reset-to-factory-defaults-with-root` to `/tmp` and runs it from there, retaining root access and the existing SSH key while disabling CWMP for the first boot.
2. **Apply de-telstra.** Runs `./de-telstra -A` to remove unnecessary Telstra-specific configuration.
3. **Reapply tch-gui-unhide.** Installs a clean web interface without the Wi-Fi Backhaul modifications or booster-specific pages.

For reference, the factory reset stage uses these commands internally:

```bash
cp -p reset-to-factory-defaults-with-root /tmp
cd /tmp
sh reset-to-factory-defaults-with-root -c -y
```

**Do not run these commands separately.** They are included here for reference only, as `restore-fresh-root` handles the entire process.

### Option 2: Restore using a custom LAN address

If you prefer to assign a specific LAN IP address after the reset, use the `-I` option.

For example:

```bash
./restore-fresh-root -I 192.168.100.2 -y
```

This performs the same restoration process but configures the modem to use `192.168.100.2` instead of its factory LAN address.

Alternatively, use `-i` to preserve the booster's existing LAN IP address.

### After the restoration

Once the process has completed and the modem has rebooted:

1. Connect a computer to one of the modem's LAN ports using an Ethernet cable.
2. Open the modem's IP address in your web browser.
3. Confirm that the standard web interface is accessible.
4. **Change the default root password from `root` to a strong, unique password.**

The modem will no longer operate as a Wi-Fi booster. Its saved upstream networks and Wi-Fi Backhaul pages will have been removed.

However, root access remains available, allowing you to continue modifying the device or repurpose it for another project.

### USB and internet requirements

The restoration process requires access to `de-telstra` and a clean copy of `tch-gui-unhide`.

- **With a USB drive connected:** The script copies the required files to the USB drive before resetting and uses them after the reboot.
- **Without a USB drive:** Connect the modem's WAN port to a LAN port on your main modem so the required scripts can be downloaded after the reset.

A log of the restoration process is saved to:

`/root/fresh-root.log`

This log can help identify any issues encountered during restoration.
