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

A normal `./wifi-backhaul -y` does not copy Wi-Fi names and does not add the Wi-Fi Booster card. Internet comes from the visible Telstra network. On a booster that is already installed, add `-U` so the LAN address, saved networks, and backhaul address stay as they are. Refresh the browser when it finishes.

### 1. Connect, and keep the password

Open Wi-Fi Backhaul, press Scan, and connect to the visible Telstra network. Type the password from the main modem. The network name is not the password.

When that link is up, the name is saved. If you join a different network later, the earlier one stays in Available Networks. A saved row says Saved and has Reconnect and Forget Network. Reconnect uses the stored password. Forget Network removes that saved network. Disconnect keeps it, and the row then offers Reconnect.

The network in Current Backhaul has Disconnect and Forget Network while it is connected.

### 2. Use the same Wi-Fi names as the main modem

`-s` copies once. `-S` keeps copying every hour.

Wait until the backhaul is connected to the visible network, then either:

```sh
./wifi-backhaul -U -s -y
```

or:

```sh
./wifi-backhaul -U -S -y
```

`-s` copies that modem's 2.4 GHz name and password, and its 5 GHz name and password, onto this booster's own client radios. If that modem has band steering on, this booster turns band steering on and uses the same name on both bands. Guest networks are left as they are. The backhaul stays on the network already chosen. If the main modem is not connected, nothing is changed. Run `-s` again when that link is up.

`-S` does that copy, then checks again every hour. If the main modem's names or band steering have changed, this booster follows. Nothing is rewritten when the names already match. The job is listed under Management, Scheduled Tasks. It starts at once an hour. Change the minute, hour, day, month, or weekday there, and the next check uses that time. Deleting that task stops the hourly check.

The Access Point form has Mirror Main Wi-Fi SSID under Protected Management Frames. Copy does the same once-only copy as `-s`. If the main modem is not connected, nothing is changed.

The booster's 5 GHz radio stays on the same channel as the main modem, because the backhaul uses that radio. The 2.4 GHz network can use another channel. Use the main modem's spelling, such as `Telstra1B279D`, with no extra hyphen.

`./wifi-backhaul -U -y` leaves the hourly copy off. `./wifi-backhaul -U -S -y` turns it on. `./wifi-backhaul -U -s -y` copies once.

### 3. Wi-Fi Booster card

```sh
./wifi-backhaul -U -b -y
```

Refresh the page. The card is left out of a normal install. `./wifi-backhaul -U -y` keeps it if `-b` was already used.

With the booster connected to the visible Telstra network, open the Wi-Fi Booster card and choose Collect main backhaul. The card reads three values and does not show the password:

1. The backhaul name, from the main modem's Wi-Fi Boosters page.
2. The password for the hidden backhaul radio. The wireless page hides that radio, so this is not the visible network's password.
3. The beacon address from the scan. The MAC on the wireless page belongs to the other radio. Saving that address makes the join fail.

Wi-Fi Backhaul then lists it as Main backhaul. Connect uses the saved password and that beacon address. The same three values are what a working booster writes under `/root/dja-backhaul/`. Firmware `20.3.c.0389` has these pages.

The backhaul uses the main modem's 5 GHz channel. If that join drops the internet, use Forget Network on that row and connect to the visible Telstra network again.

### 4. Copy the names and aim the backhaul at the hidden network

```sh
./wifi-backhaul -U -bs -y
```

`-bs` is `-b` and `-s` together. It adds the Wi-Fi Booster card, copies the visible 2.4 GHz and 5 GHz names and passwords once, follows that modem's band steering, and then points the backhaul at the hidden network. `-bS` does the same and keeps checking the names every hour. Connect to the visible Telstra network first, so it can read that network's name, password, and beacon address.

If the beacon is not in the scan yet, the switch waits. If the internet drops, Forget that network in Wi-Fi Backhaul and join the visible Telstra network again. Type that password again if the saved one was replaced.

### 5. Update, then run tch-gui-unhide

```sh
curl -skLo wifi-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul
chmod +x wifi-backhaul
./wifi-backhaul -U -y
```

Saved networks, the backhaul address, and this booster's LAN address stay as they are.

```sh
./tch-gui-unhide -dy -y
```

That rewrites the pages and puts the booster pages back. Content Sharing, Mobile, Printer Sharing, Parental Controls, and Relay Setup stay off the dashboard. The missing-card messages from those removed pages are not printed. If the tch-gui-unhide `get` command replaces `/root/tch-gui-unhide`, run `./wifi-backhaul -U -y` again.

## Read the hidden network on the main modem

On the main modem, `./main-backhaul` reads the backhaul radio, that radio's password, and the address the radio transmits. Copy the files across and the Wi-Fi Backhaul card can connect with them:

```sh
curl -skLo main-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/main-backhaul
chmod +x main-backhaul
./main-backhaul
```

Copy `/tmp/dja-main-backhaul` to the booster. The password file is included and is not printed. On the booster:

```sh
./take-main-backhaul /tmp/dja-main-backhaul
```

The Wi-Fi Backhaul card then lists that network as Main backhaul. Connect uses the saved password, so it is not typed into the page.

## Update an existing booster

```sh
./wifi-backhaul -U -y
```

This downloads the latest installer and applies it. The upstream Wi-Fi, the saved radio lock, the backhaul address, this booster's LAN address, and the USB backup time stay as they are. The backhaul link stays up. Refresh the browser when it finishes.

The first time this command is used, download the installer and then update:

```sh
curl -skLo wifi-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul
chmod +x wifi-backhaul
./wifi-backhaul -U -y
```

After that, `/root/wifi-backhaul -U -y` downloads and applies a newer copy.

## Keeping the pages after an unhide upgrade

```sh
./tch-gui-unhide -U -y
```

That upgrade rewrites the web pages, then puts the booster pages back. Content Sharing, Mobile, Printer Sharing, Parental Controls, and Relay Setup stay removed. The upgrade no longer prints `No such file or directory` for those cards. If you run the tch-gui-unhide `get` command again and it replaces `/root/tch-gui-unhide`, run `./wifi-backhaul -U -y` once more so later upgrades keep the pages.

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
| `-U` | Update an existing booster and keep its saved settings |
| `-b` | Add the Wi-Fi Booster card. A normal install leaves that card out. `./wifi-backhaul -U -y` keeps the card if `-b` was already used |
| `-s` | Copy the upstream modem's 2.4 GHz and 5 GHz names and passwords onto this booster's client radios once, and turn band steering on here when that modem has it on. If the main modem is not connected, nothing is changed. The backhaul stays on the network already saved |
| `-S` | Do that copy, then check again every hour. The job is under Management, Scheduled Tasks, starting at once an hour. Change the time there. The hourly copy runs only when this command includes `-S` |
| `-y` | Do not ask for confirmation |
| `-n` | Accepted |
| `-t` | Check the packaged files and exit |

The order for `-s`, `-S`, `-b`, and `-bs` is in How to use it above. `-s` copies the upstream 2.4 GHz and 5 GHz names and passwords once and leaves the backhaul on the visible network. Copy on the Access Point form does that too. `-S` keeps checking every hour from Scheduled Tasks, and the time can be changed there. `-b` adds the Wi-Fi Booster card, which collects the hidden network's name, password, and beacon address. `-bs` copies the names once and then aims the backhaul at that hidden network. `-bS` does that and keeps checking the names every hour. It uses the same 5 GHz channel as the visible Telstra network.

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
