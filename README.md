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

The Advanced dashboard keeps the cards that matter on a booster.

- Broadband is not shown. Mobile, DNS, Firewall, xDSL, NAT Helpers, and Relay Setup are removed, including from Management. Mobile is disabled.
- Eco Settings, Diagnostics, Packages, System Extras, and Devices are hidden. Management can turn those cards on. Device Security is removed.
- Management has one Wi-Fi Backhaul switch. That switch opens the backhaul card.
- Internet Access shows the upstream network, signal, and rate. Backhaul download and upload sit in the corner of that card.
- Wi-Fi Backhaul shows the upstream name, signal, rate, channel, width, and uptime. The password is the one on the main modem. The network name is not accepted as the password. The scan list is titled Available Networks, and its columns line up with Current Backhaul. A network this booster has joined stays in that list as Saved, with Reconnect and Forget Network, and its password is kept when another network is chosen. A connected network offers Disconnect and Forget Network. Disconnect keeps the saved network and then offers Reconnect and Forget Network. Forget Network deletes that saved network. Connecting to a network saves a lock to the radio it joined. Disconnect drops that lock. A different network drops the old lock and saves the new radio after it connects. Reconnect saves the radio it joins.
- Wi-Fi Booster is not on the dashboard unless `./wifi-backhaul -b` was used. That card is described under Installer options.
- Wi-Fi shows the local 2.4 GHz and 5 GHz names, with a gap between the two bands.
- Local Network shows this booster's address, and the backhaul address and gateway while the backhaul link is up.
- USB Backup is the USB backup and restore page described below.
- Management is where card names are shown and cards are switched on or off. The backup card is labelled USB.
- Diagnostics no longer has a TCP Dump tab.

CPU, RAM, Backhaul Download, and Backhaul Upload are shown when `./tch-gui-unhide -Cs` was not used. `-Cs` replaces those four with the summary chart card, and `./wifi-backhaul` leaves them hidden.

## Local Network page

- Local Network Subnet is shown and cannot be edited.
- IPv6 is a read-only On or Off. It follows router advertisements from the main modem. It does not turn IPv6 on for the booster.
- Local Domain Name and the booster IPv4 address can be changed. Saving the address changes this booster's LAN address.
- Guest interfaces are not listed.

## Wi-Fi page

- The tabs are the local 2.4 GHz and local 5 GHz networks.
- Under Protected Management Frames, Mirror Main Wi-Fi SSID has Copy. Copy takes the main modem's names once. If that modem is not connected, nothing is changed.
- Guest names are not listed.
- Wireless Control and Wifi Nurse are not listed.
- Changing the local name or password is not applied to the backhaul interface.

## USB backup

The old commands are still on the booster. The USB Backup card runs them.

- Schedule daily backup turns the early-morning backup on. The same button then says Turn off daily backup, which removes it. Hour and Minute set the time: 4 and 8 is 4:08am. That job saves the configuration, environment, and overlay.
- The same job is a row under Management, Scheduled Tasks, once daily backup is on. The command is `/root/mtd-backup -d backups -ceoy`. Minute and Hour there are the backup time. Change them on this page or on the USB Backup card. Turning Enabled off, or deleting the row, turns the daily backup off.
- Backup now writes that same backup straight away.
- Restore and reboot writes the saved configuration back and restarts the booster. It asks before it does that.

A USB stick has to be plugged in first. The card shows whether one is inserted.

`mtd-restore -fsr` does not work on this firmware. `-f` is not a valid option, so that command exits without restoring anything. The restore button runs `mtd-restore -sr`, which restores the saved configuration and then reboots.

## Installer options

### pre-booster

```text
./pre-booster -w -i 192.168.100.4 -y
```

| Option | Effect |
| --- | --- |
| `-i` | LAN address for this modem. Required. On a `192.168.100.0` network the main modem is `192.168.100.1`, so pick another free address |
| `-w` | Wired start. Plug the WAN port into a LAN port on the main modem. Waits until that modem gives the WAN port an address, checks the `-i` address is free and on that network, then saves it. The WAN session stays up |
| `-y` | Do not ask for confirmation |

With no `-w`, `./pre-booster -i 192.168.100.4 -y` moves the LAN address and restarts the network. DHCP stays on.

After `-w`, run `./wifi-backhaul -y`. The connection drops, then the same cable opens the new address. Connect the Wi-Fi backhaul there. When that link is up, unplug the cable and move the booster.

### wifi-backhaul

```text
./wifi-backhaul -y
```

| Option | Effect |
| --- | --- |
| `-i` | Not required. `pre-booster` has already set the address |
| `-n` | Accepted |
| `-t` | Check the packaged files and exit |

`-U`, `-s`, `-S`, `-b`, `-bs`, `-bS` and `-y` are listed in the command reference under How to use it.

### restore-fresh-root

```text
./restore-fresh-root -y
./restore-fresh-root -I 192.168.100.2 -y
```

| Option | Effect |
| --- | --- |
| `-I` | LAN address after the reset. `./restore-fresh-root -y` leaves this off and uses the factory LAN address |
| `-i` | Keep the LAN address this booster has now. Do not use this with `-I` |
| `-y` | Do not ask for confirmation |

## Put the booster back

`restore-fresh-root` removes the Wi-Fi booster and returns the modem to a freshly rooted setup, the same path as the [tch-gui-unhide wiki](https://github.com/seud0nym/tch-gui-unhide/wiki). The root password is set back to `root`. The upstream network and the booster pages are not kept. This is not the USB backup restore. That restore puts the booster setup back.

`./wifi-backhaul` installs `restore-fresh-root` in `/root`. From that prompt, run `./restore-fresh-root`. The same command also works without `./`.

### `./restore-fresh-root -y`

This does the three steps and returns the modem on its factory LAN address:

1. Copy the reset script to `/tmp` and run it from there. That keeps root and the current SSH key, and turns CWMP off for the first boot.

```sh
cp -p reset-to-factory-defaults-with-root /tmp
cd /tmp
sh reset-to-factory-defaults-with-root -c -y
```

2. `./de-telstra -A`
3. A clean `./tch-gui-unhide`, without the booster pages.

```sh
./restore-fresh-root -y
```

### `./restore-fresh-root -I 192.168.100.2 -y`

This does the same reset, then brings the modem back on the address passed with `-I`.

```sh
./restore-fresh-root -I 192.168.100.2 -y
```

After the reboot it is a normal modem again. Plug a computer into a LAN port and open that address. If a USB stick is already inserted, the script copies `de-telstra` and a clean unhide onto it and uses those after the reboot. With no USB stick, plug the WAN port into the main modem so those two scripts can download. The result is written to `/root/fresh-root.log`.
