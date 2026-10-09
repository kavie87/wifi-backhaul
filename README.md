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

`./wifi-backhaul -y` prepares the booster and leaves the existing Ethernet connection in place. It does not convert the WAN port, replace the LAN subnet, disable DHCP, or create a temporary smaller subnet.

On a fresh installation the script will:

- Disable unnecessary services, including WPS and UPnP.
- Remove unused service cards from the web interface.
- Keep Ethernet WAN working, and keep the physical WAN port configured as WAN.
- Keep the LAN management address, subnet and DHCP server set by `pre-booster`.
- Leave WAN masquerade as it is.
- Record the WAN port for a later handover. Recording it does not move the port.

While that port is still the WAN port, the modem's own WAN service requests a DHCP address when a cable is linked. The gateway and default route come from that lease. No extra WAN command is required. Plugging the cable in after installation does the same thing until the handover has finished. The Ethernet WAN network has to be a different subnet from the booster's LAN. The Wi-Fi link to the main modem and the booster's LAN stay in one `/24`.

Before the handover, the booster's DHCP server and WAN masquerade stay in place. A computer on a LAN port can use the booster as its gateway and reach the internet through Ethernet WAN. That path was confirmed on an already installed spare while Wi-Fi was stopped. It has not been repeated as a fresh `./wifi-backhaul -y` with the cable already in the WAN port.

Once the Wi-Fi station has an address, its address script can replace the booster's DNS servers before the Wi-Fi check has passed. A ping to an internet address can still leave through Ethernet WAN while a name lookup uses those new servers.

The Internet Access and Local Network cards read the live Ethernet route. When that route is an Ethernet port and Wi-Fi is not yet verified, the card code shows the WAN connection and its address. On the spare those files were loaded after the web server was reloaded. A screenshot of the new wording was not kept, so the on-screen result is not recorded as a separate check.

The LAN network is not restarted when that address is already in place, so the Ethernet session stays up. Enter the upstream Wi-Fi name and password afterwards in the Wi-Fi Backhaul card. Saving those details does not disable Ethernet WAN. The management session stays on the existing LAN address while the booster tries to join. If a Wi-Fi name and password are already saved, the installer starts the backhaul service and the same check can finish the handover in that run. When Wi-Fi is unavailable, the check stops and Ethernet WAN stays.

The booster then checks the Wi-Fi station itself. A route that still works only through Ethernet WAN is not treated as success. The check has to confirm association, WPA authentication, a completed upstream DHCP lease or a valid static address, and a gateway that answers from the station's own address. The full list is under [Safe DHCP handover](#safe-dhcp-handover).

Only after that check passes does the WAN port become an extra LAN port. When downstream DHCP forwarding is in use, the booster turns off its own DHCP server at that point, so LAN clients are addressed by the main modem. The management address stays the same. The management session can drop briefly while the port changes. Reconnect on the same LAN address. A cable that was in the WAN port is then on the LAN.

If the Wi-Fi check fails, Ethernet WAN and the existing LAN configuration stay as they are. A wrong password, a missing network, a failed DHCP exchange or an unreachable gateway does not move the WAN port. The Wi-Fi details can be entered again.

If the port change starts and the final checks fail, the previous WAN, DHCP and management configuration is restored. The script starts a one-shot watchdog before that port change. The watchdog still restores the saved configuration if the SSH session has already dropped. It runs once, and it does not keep switching the port between WAN and LAN. If the watchdog cannot be started, the handover stops before the port is moved and Ethernet WAN stays as it is.

A booster whose WAN port is already a LAN port is detected and left that way. The conversion is not repeated, and a later Wi-Fi outage does not move the port back.

### Step 3: Connect the Wi-Fi backhaul

After installation, open the booster's web interface using the IP address configured earlier. A management cable in a LAN port can stay connected while you do this.

For example:

`http://192.168.100.4/`

Locate the **Wi-Fi Backhaul** card and select the wireless network you want the booster to connect to.

Enter the network password and establish the connection. A management cable in a LAN port can stay connected while the booster checks Wi-Fi. Unplug a WAN cable that is on another subnet before that check finishes.

The handover runs by itself only after the checks in Step 2 succeed. On this DJA0231 the physical WAN jack is `eth4`. It is not the jack labelled LAN 4. Wait until the booster answers again on its LAN address. Confirm the handover has finished before you disconnect a cable: the old WAN port is now an extra LAN port, and the booster still reaches the main modem over Wi-Fi.

A cable on a different subnet from the booster LAN has to come out before that check passes. The jack joins the LAN as soon as Wi-Fi is verified, and that cable would then be attached to the booster LAN. A management cable can stay in a LAN port. Then:

1. Disconnect the cable from the old WAN port. That jack is now a LAN port.
2. Move the booster to its intended location.
3. Reconnect to the booster's web interface to confirm that the wireless backhaul is still operational.

Your rooted Telstra DJA0231 should now be operating as a wireless booster, using Wi-Fi for its connection to the main modem while providing its own 2.4 GHz and 5 GHz wireless networks for nearby devices.

## Safe DHCP handover

Ethernet WAN stays up while the upstream Wi-Fi network is being chosen and checked. Saving a Wi-Fi name and password does not, by itself, disable the WAN port or the booster's DHCP server. A leftover `/root/dja-backhaul/waiting-netmask` file from an older install is ignored. An update does not apply that old temporary subnet.

The booster's own upstream address and downstream client addressing are separate. Automatic (DHCP) or Static IP on the Wi-Fi Backhaul card is the address of this booster's 5 GHz station. Downstream clients are addressed by `relayd`. The packaged downstream mode is `relay-experimental`, which forwards their DHCP requests to the upstream modem. Writing `static` into `/root/dja-backhaul/client-addressing` leaves that forwarding off and keeps the booster's own DHCP server. An update does not change a mode that is already saved. The station is not added to the LAN bridge. The management address and the upstream network have to be in the same `/24`. A different mask is rejected.

The station does not currently send a DHCP hostname. The main modem can therefore list it as `Unknown-` followed by the station MAC. Setting the booster's system hostname does not, by itself, change that label. Downstream devices keep their own MAC addresses on the booster LAN. The upstream Wi-Fi list shows the station, because this is a three-address client with a pseudo-bridge, not a transparent bridge.

**Before Wi-Fi verification:** Ethernet WAN remains active and the WAN port keeps its original function. Link detection, the DHCP lease, the gateway and the default route stay with that WAN service. WAN masquerade and the LAN DHCP server stay as well. The LAN address stays where `pre-booster` left it, unless setup asked for a different address. Restarting the backhaul service does not move the port before the Wi-Fi check passes. The station address script can still replace the DNS server list once the station has an address. That is earlier than the gateway ping.

While that port is still WAN and the cable is linked, the WAN light stays on. Online is green while internet answers through Ethernet WAN. On the spare, both lights were green with WAN address `192.168.29.11`. After the port becomes a LAN port, the WAN light is turned off. Online then follows the Wi-Fi path. That later change has not been checked on the hardware yet.

**Ethernet WAN and the LAN use different subnets.** The Wi-Fi upstream and the booster LAN have to share one `/24`. An Ethernet WAN on that same `/24` overlaps the LAN, so it is not a usable internet path. A WAN on another subnet can provide internet until the handover.

These checks have to pass on the Wi-Fi station. A ping that can still leave through Ethernet WAN is not enough:

1. The station has associated with the selected access point.
2. WPA authentication has completed.
3. The station is on the selected SSID, and on the selected BSSID when one was saved.
4. Upstream DHCP has completed, or the saved static address is valid.
5. The address, `/24` mask and gateway are valid and in the same network as the LAN management address.
6. The management address does not conflict with the upstream address or another device on that network.
7. The upstream gateway answers a ping from the station's own address.

**After successful Wi-Fi verification and handover:** Wi-Fi becomes the upstream connection, and the physical WAN port becomes an additional LAN port. On this DJA0231 that port is `eth4`. The booster then disables its own DHCP server when `relayd` is set to forward DHCP from the upstream modem, so LAN clients are addressed by that modem. The management address stays the same. The success marker is `/root/dja-backhaul/wan-as-lan`. This change can briefly interrupt a management session. The conversion runs once. A later Wi-Fi drop does not turn the jack back into a WAN port, and plugging a cable into it does not start Ethernet WAN again.

**If verification fails:** The booster keeps its original Ethernet WAN and LAN configuration. A wrong Wi-Fi password, a missing SSID, a failed upstream DHCP exchange, or an unreachable gateway does not move the WAN port or disable LAN DHCP. The Wi-Fi details can be entered again.

If the port move starts and the final checks fail, the previous network, DHCP and firewall configuration is restored, including the WAN port and the management address. The script starts a one-shot watchdog before the move. That watchdog performs the restore even if the SSH session has already dropped. It runs once. It does not keep switching the port between WAN and LAN. If the watchdog cannot be started, the handover stops before the port is moved and Ethernet WAN stays as it is. Another attempt waits until Connect is used again.

After a reboot:

- If Wi-Fi backhaul has never completed handover, Ethernet WAN stays as it was.
- If handover completed, the WAN port remains a LAN port and Wi-Fi backhaul starts again. The conversion is not repeated.
- A temporary Wi-Fi outage does not move the port back to WAN and does not rebuild the network.

If Wi-Fi backhaul stays down and Ethernet WAN is needed again:

```bash
/root/dja-backhaul/wan-handover.sh recover
```

That restores the configuration saved before the handover. An older installation that had already turned the WAN port into a LAN port before this handover existed has no earlier WAN configuration to restore. `restore-fresh-root` is the full return to a clean rooted modem.

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
| `-Cs` | Shows one summary chart. Wi-Fi Backhaul reads that as `web.card_Charts.hide=0`. When that chart is already on, `pre-booster` and a fresh Wi-Fi Backhaul install keep Backhaul Download and Backhaul Upload hidden. |
| `-tc` | Enables the classic theme. |
| `-a5` | Displays five cards across the web interface. |
| `-y` | Automatically confirms prompts. |

If a summary chart is already on, `pre-booster` and a fresh Wi-Fi Backhaul install keep Backhaul Download and Backhaul Upload hidden. CPU, RAM and the summary chart stay as they are. If the summary chart is not in use, a fresh install shows the CPU, RAM, Backhaul Download and Backhaul Upload cards. An update with `-U` leaves every card as it already is.

**Security note:** The `-dy` option disables password protection for the web interface. Only use this on a trusted network.

### Step 4: Install Wi-Fi Backhaul

With the modem reset and the Technicolor modifications installed, you're ready to configure Wi-Fi Backhaul.

Follow the instructions in the **Download and install** section above to:

1. Run `pre-booster` and assign the booster an available IP address on your main network.
2. Install the `wifi-backhaul` script.
3. Open the Wi-Fi Backhaul card and connect to your main modem's wireless network. Ethernet WAN stays up while that connection is checked. A WAN cable on another subnet has to be unplugged before the check passes.
4. After the handover has finished, and the old WAN port is a LAN port, disconnect that cable and relocate the booster.

The backhaul connection uses DHCP by default. If you prefer a static IP address, this can be configured directly through the Wi-Fi Backhaul card.

**Re-running the installer:** Running `./wifi-backhaul` again preserves any previously saved upstream Wi-Fi network and backhaul IP configuration.

## How to use it

By default, running `./wifi-backhaul -y` configures the booster to connect to a visible Wi-Fi network. It does not automatically copy the main modem's Wi-Fi settings or enable the optional Wi-Fi Booster card.

Additional options are available if you want to mirror your main modem's Wi-Fi settings or use BH backhaul mode. **BH** means the backhaul SSID used by compatible Telstra equipment. BH backhaul mode connects the booster to that BH network. Standard Wi-Fi backhaul connects it to a normal 5 GHz Wi-Fi SSID. The details are under [Enable the Wi-Fi Booster card](#3-enable-the-wi-fi-booster-card).

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

#### Backhaul IP

Open the **Backhaul IP** tab on the same card to see how the upstream connection is addressed.

The tab reads the live connection. It does not need the connection to have been started by `./wifi-backhaul`. A link made from this card, from UCI, or from the router's own wireless pages is shown the same way, as long as the upstream Wi-Fi is actually connected.

It looks for the wireless station that owns the IPv4 default route. That station is not assumed to have a particular interface name, and it does not have to be listed as a UCI network interface. If the station is a bridge member and has no address of its own, the tab uses the bridge that owns the address. The booster's LAN address on `br-lan` is not shown as the backhaul address when the upstream address is on the station.

DHCP and Static IP come from the interface configuration. A UCI `proto` on that interface is used when one exists. Otherwise a DHCP client running on the interface selects Automatic (DHCP). Otherwise the saved backhaul address file is used. An address on its own is not treated as Static IP.

In Automatic (DHCP), the assigned address, subnet mask, gateway and DNS servers are shown in read-only fields. DNS is the resolver list for that connection when it can be identified. "From the modem" remains only when those servers cannot be identified.

In Static IP, the saved address, subnet mask, gateway and DNS are filled in and can be edited. An existing static configuration is not replaced with blanks. Switching from DHCP to Static IP fills the fields from the current connection so they can be edited. DNS already saved is kept unless those fields are changed. Leave DNS empty on a static connection to keep using the modem's DNS.

The Current Backhaul panel shows the live address, gateway and mode. It does not repeat unsaved form values. **Refresh** reloads that panel. If the form has unsaved edits, Refresh does not replace them. Cancel restores the saved form. Unavailable is shown only when that value cannot be determined, including when the upstream link is down.

Saving writes the address mode on the backhaul interface and restarts the upstream Wi-Fi connection. It does not change the booster's LAN address or the other wireless settings. If this page was opened on the backhaul address, the page warns that saving will disconnect it. A static address has to use subnet mask `255.255.255.0`, and the gateway has to be in that same network. Invalid values are rejected before the connection is restarted. The saved address is kept across a reboot.

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
./wifi-backhaul -S -y
```

On a booster that is already installed, include `-U` so the saved settings stay as they are:

```bash
./wifi-backhaul -U -S -y
```

`-S` turns on automatic synchronisation of the booster's local 2.4 GHz and 5 GHz Wi-Fi with the main modem. It copies those names and passwords, then keeps checking them. It also adds a scheduled task. That task is not listed until `-S` has been run. Running `-S` again keeps the existing schedule and does not add a second task.

`-s` copies the settings once. `-S` keeps the scheduled check. If you pass both, the scheduled check is the one that stays.

Both options:

- Copy the 2.4 GHz and 5 GHz SSIDs and passwords.
- Enable band steering on the booster if it is enabled on the main modem, using the same SSID across both bands.
- Leave guest Wi-Fi networks unchanged.
- Preserve the existing wireless backhaul connection.
- Make no changes if the main modem is not connected.

#### Automatic synchronisation

After `-S`, open **Management → Scheduled Tasks**. The new task checks the main modem at the start of every hour:

```cron
0 * * * * /root/dja-backhaul/sync-upstream-ssid
```

The main modem must be connected and reachable. The check looks at its 2.4 GHz and 5 GHz names, passwords and band steering. The booster is updated only when something there has changed. If nothing has changed, the local Wi-Fi is left as it is. The task checks at the selected interval. It does not change the SSID or password every time it runs.

Change the schedule in **Management → Scheduled Tasks**. You do not need to run `./wifi-backhaul -S` again just to change the time. Change only the five timing fields. Leave the command as:

`/root/dja-backhaul/sync-upstream-ssid`

| Frequency | Minute | Hour | Day | Month | Weekday |
|---|---|---|---|---|---|
| Every hour (default) | `0` | `*` | `*` | `*` | `*` |
| Every 30 minutes | `*/30` | `*` | `*` | `*` | `*` |
| Every 6 hours | `0` | `*/6` | `*` | `*` | `*` |
| Daily at 3:00 AM | `0` | `3` | `*` | `*` | `*` |

Every 6 hours, with Minute left at `0` and Hour set to `*/6`, runs at 12:00 AM, 6:00 AM, 12:00 PM and 6:00 PM.

`./wifi-backhaul -U -S -y` keeps a timing you have already changed, including a custom interval such as every 30 minutes or every 6 hours. It replaces the command only. It puts the task back to every hour only when that row is missing. A row that was turned off under Scheduled Tasks is turned back on by `-S`, with the same timing.

Running `./wifi-backhaul` or `./wifi-backhaul -U -y` again keeps an enabled scheduled task. It does not create another one, and it does not remove the task. A task you deleted or turned off in **Management → Scheduled Tasks** stays off until you run `-S` again.

#### Remove SSID synchronisation (`-Sr`)

```bash
./wifi-backhaul -Sr
```

`-Sr` removes the scheduled synchronisation task and the marker that asks for it to be installed. It removes only crontab lines that run `/root/dja-backhaul/sync-upstream-ssid`. Other scheduled tasks, including a USB backup, are left alone. The current Wi-Fi name, password, upstream connection and other Wi-Fi Backhaul settings stay as they are. The synchronisation script stays installed, so `-S` can turn the check on again later. Running `-Sr` again is safe. If the task is not installed, it reports:

`SSID synchronisation is not currently enabled. Nothing to remove.`

When removal succeeds, it reports:

`SSID synchronisation has been disabled. Your current Wi-Fi configuration has been preserved.`

Do not combine `-Sr` with `-U`, `-S`, `-s`, `-b`, `-i` or `-t`. `./wifi-backhaul -U -Sr` is rejected. Run `./wifi-backhaul -Sr` on its own. That removes the check and does not run the rest of the installer. An update with `./wifi-backhaul -U -y` keeps the synchronisation state that is already there.

Deleting the task, or turning Enabled off, also stops the check. The next `./wifi-backhaul` run sees that the task is gone and does not put it back. The Wi-Fi name already in use stays as it is.

Check that the task was installed under **Management → Scheduled Tasks**, or on the booster:

```bash
grep sync-upstream-ssid /etc/crontabs/root
```

One line should be present. The default is `0 * * * * /root/dja-backhaul/sync-upstream-ssid`. After `-Sr`, that line is gone.

#### Remembered configuration

Running `./wifi-backhaul` again reads the saved upstream network, backhaul mode, address settings and the real Scheduled Tasks row. Existing values are shown as defaults. Press Enter to keep a value. Type a new value to replace it. The installer asks you to confirm before it saves.

A saved password is not printed. The prompt says `[Saved – press Enter to keep]`. Pressing Enter keeps the password that is already stored. A new password replaces it. Asterisks are not stored as a password. `./wifi-backhaul -U -y` skips these questions and does not replace a saved password with a blank. An update or a reinstall keeps those saved files, including an enabled synchronisation schedule, a custom schedule, and a schedule that has been switched off, instead of replacing them with installer defaults.

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

**BH** means the backhaul SSID used by compatible Telstra equipment. This section uses the names below.

- **BH network** or **BH SSID:** the separate wireless network that a compatible upstream router provides for boosters. It has its own password, and it is a different SSID from the normal 5 GHz Wi-Fi name that phones and laptops join.
- **BH backhaul mode:** the experimental feature turned on by `./wifi-backhaul -b`. It prepares this booster to connect to the upstream BH SSID.
- **Standard Wi-Fi backhaul:** the booster joins a normal 5 GHz Wi-Fi SSID on the upstream router.
- **Upstream router** or **main modem:** the device providing that wireless connection.
- **Booster:** the rooted Telstra Smart Modem Gen 2 running Wi-Fi Backhaul.

Standard Wi-Fi backhaul uses the visible 5 GHz SSID. BH backhaul mode uses the BH SSID. The two ways of reading that SSID do not use the same beacon.

The Wi-Fi Booster card does it with **Collect main backhaul** after the booster is already connected to the visible Wi-Fi. That path reads the BH SSID from the upstream router's Wi-Fi Boosters page and the password from that router's hidden QR page. The beacon is chosen from a 5 GHz scan. A beacon advertising the BH SSID is preferred. Otherwise a hidden beacon with the same address prefix and channel as the visible network is used. If the scan has no matching beacon, collection stops and the current network stays. A collected beacon is not confirmation that the booster has joined the BH network.

The `main-backhaul` script, run on the upstream router, selects the wireless interface marked `backhaul=1` and reads that interface's SSID and password. Its beacon is the address the radio transmits (`wl cur_etheraddr`). If the radio does not report that address, the script uses the interface address and says so. If no interface is marked `backhaul=1`, collection stops. Neither path prints the password.

The option that turns BH backhaul mode on is `-b`. On a booster that is already installed, include `-U` as well so the saved network is kept.

> **Experimental.** BH backhaul mode is in beta. Initial testing suggests that it can work when the upstream router is a Telstra Smart Modem Gen 3. Using a rooted Telstra Smart Modem Gen 2 as that upstream router has not been confirmed. Other Technicolor modems, and third-party routers or access points, have not been tested enough to draw a conclusion. More testing is needed before compatibility with any further device can be confirmed. The feature may not work with every upstream router or firmware version.

| Main / Upstream Router | Compatibility | Testing Status |
|---|---|---|
| Telstra Smart Modem Gen 3 | Appears to work | Initial testing successful; further testing required |
| Telstra Smart Modem Gen 2 (rooted) | Unknown | Not yet confirmed |
| Other Technicolor modems | Unknown | Not tested |
| Third-party routers / access points | Unknown | Not tested |

These results are preliminary. They will be updated as more testing is completed. A device is not listed as incompatible only because it has not been tested yet.

#### Community testing and feedback

Results from other routers and firmware versions are welcome. Please open a [GitHub Issue](https://github.com/kavie87/wifi-backhaul/issues) and, where you can, include:

- The main router model and firmware version.
- The booster model and firmware version.
- Whether each device is rooted.
- Whether standard Wi-Fi backhaul, using the normal 5 GHz SSID, works.
- Whether BH backhaul mode works.
- Whether the connection is still up after a reboot.
- Any connection problems or unexpected behaviour.

Remove Wi-Fi passwords, backup passwords and any other sensitive information from logs and screenshots before you post them.

#### Further testing

More testing is still needed before these points can be confirmed:

- Gen 2 to Gen 2 in BH backhaul mode.
- Gen 2 and Gen 3 used together, across firmware versions.
- Other Technicolor devices.
- Third-party wireless equipment.
- Whether BH backhaul mode comes back by itself after a reboot.
- Whether the connection stays up over a long period.
- What happens when the upstream BH network disappears.

Those items have not been tested, or have not been tested enough to confirm. They are not known failures. Separately, the installer will not start BH backhaul mode when the BH SSID, password or beacon cannot be read, and it leaves the current network in place. If the visible Wi-Fi link is not up yet, a combined `-bs` or `-bS` run waits and does not claim the link is up. If the beacon is not in the scan, the attempt stops and the current network stays. Starting the attempt is not the same as a finished connection: the Wi-Fi Backhaul card is what shows whether **Main backhaul** actually connected. Joining the BH network can drop internet access. If that happens, use Forget Network on that entry and connect again to the visible Wi-Fi network.

`./wifi-backhaul -b` enables the Wi-Fi Booster card and turns BH backhaul mode on. It does not join the BH SSID by itself. After you connect, the card shows whether the BH network is the active link. The channel is saved when it is a 5 GHz channel. The password is stored in a file and is not printed.

Collection of the BH SSID has been identified on firmware `20.3.c.0389`. That does not by itself confirm a successful join on every firmware.

To enable the card on an existing booster, run:

```bash
./wifi-backhaul -U -b -y
```

Refresh the web interface once the installer has finished.

The card is not enabled during a standard installation. However, once enabled using `-b`, it remains available when running `./wifi-backhaul -U -y` again.

#### Connecting to the BH network

Before proceeding, connect the booster to the upstream router's visible Wi-Fi network. That visible connection is standard Wi-Fi backhaul, and the card needs it before it can read the BH SSID.

Then:

1. Open the Wi-Fi Booster card.
2. Select **Collect main backhaul**.
3. Allow the card to retrieve the BH SSID, password and beacon.
4. Open Wi-Fi Backhaul and locate the network listed as **Main backhaul**.
5. Select **Connect** to join the BH network.

The Wi-Fi Backhaul card is the place to confirm the result. **Main backhaul** should be the active network under Current Backhaul, with a signal reading, and internet through the booster should still work. The installer's line `Hidden backhaul: Connection attempt started` only means the attempt began. It does not mean the join has finished.

The collection process retrieves three values:

- **BH SSID:** the BH network name, read from the upstream router's Wi-Fi Boosters page. It is not the normal 5 GHz Wi-Fi name.
- **BH password:** the password for that BH SSID. It is not the visible Wi-Fi password.
- **Beacon address (BSSID):** chosen from a 5 GHz scan while the booster is on the visible network. A beacon advertising the BH SSID is preferred. Otherwise a hidden beacon with the same address prefix and channel as the connected network is used. If neither is in the scan, collection fails. This is separate from the beacon `main-backhaul` reads with `wl cur_etheraddr`.

These values are saved for future connections. The password is not displayed in the card.

The same information is stored by a working Telstra booster under `/root/dja-backhaul/`.

This collection has been identified on firmware `20.3.c.0389`.

**Troubleshooting:** The BH network uses the upstream router's 5 GHz channel. If connecting causes internet connectivity to drop, use Forget Network on that entry and reconnect to the visible Wi-Fi network.

### 4. Mirror Wi-Fi settings and use BH backhaul mode

If you want to mirror the main modem's Wi-Fi settings and also use BH backhaul mode, both can be combined in one command. This is the same experimental feature described above, including the compatibility limits. `-b` on its own still only enables the card. `-bs` and `-bS` also attempt to join the BH SSID.

#### One-time Wi-Fi synchronisation with BH backhaul mode (`-bs`)

```bash
./wifi-backhaul -U -bs -y
```

This will:

- Enable the Wi-Fi Booster card.
- Copy the main modem's 2.4 GHz and 5 GHz SSIDs and passwords.
- Match the main modem's band steering configuration.
- Attempt to switch from standard Wi-Fi backhaul to the BH SSID.

#### Automatic Wi-Fi synchronisation with BH backhaul mode (`-bS`)

```bash
./wifi-backhaul -U -bS -y
```

Performs the same initial configuration but also creates an hourly scheduled task to keep the booster's Wi-Fi settings synchronised with the main modem.

**Before running either command:** Connect to the upstream router's visible Wi-Fi network first. The script needs that link before it can read the BH SSID.

If the visible Wi-Fi link is not up yet, the switch waits. If the BH beacon is not in the scan, the switch stops and the current network stays.

If joining the BH network causes internet connectivity to drop, forget that network in the Wi-Fi Backhaul card and reconnect to the visible Wi-Fi network. You may need to enter its password again if the saved credentials were replaced.

### 5. Updating Wi-Fi Backhaul

Updating an installed booster, including what `-U` keeps and how to retain the pages after a `tch-gui-unhide` upgrade, is covered in [Update an existing booster](#update-an-existing-booster).

**Important:** An update keeps an enabled SSID synchronisation task. Use `./wifi-backhaul -Sr` when that task should be removed. `-S` turns it on again.

### Command reference

| Command option | Purpose |
| --- | --- |
| `-U` | Download the current installer when possible, then update without clearing the saved network, an enabled synchronisation task, a custom schedule, or a task that has been switched off |
| `-s` | Copy the main modem's Wi-Fi settings once |
| `-S` | Copy settings and enable hourly synchronisation |
| `-Sr` | Remove hourly synchronisation. The current Wi-Fi name, password and network stay as they are. Run it on its own. `./wifi-backhaul -U -Sr` is rejected |
| `-b` | Turn on BH backhaul mode by enabling the Wi-Fi Booster card. This does not join the BH SSID by itself |
| `-bs` | Copy settings once and attempt to join the BH SSID |
| `-bS` | BH backhaul mode with hourly Wi-Fi synchronisation |
| `-y` | Automatically confirm installer prompts |

## Read the BH SSID on the main modem

If you prefer to retrieve the BH SSID directly from your main Telstra modem, you can use the `main-backhaul` script.

This script looks up the wireless interface marked `backhaul=1` and saves that interface's SSID, password and beacon address (BSSID). The beacon is `wl cur_etheraddr`, or the interface address when the radio does not report it. It does not print the password. `take-main-backhaul` imports these files. They are not the 5 GHz scan result used by **Collect main backhaul**.

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

### Step 3: Connect to the BH network

Open the booster's web interface and navigate to the Wi-Fi Backhaul card.

The imported network will appear as **Main backhaul**.

Select **Connect** to establish the wireless backhaul connection using the saved credentials.

You do not need to manually enter the BH SSID password.

## Update an existing booster

Use this on a booster that already has Wi-Fi Backhaul. `-U` keeps the saved setup, including the LAN address and subnet. A fresh install does not replace that subnet with a smaller one. The update itself does not move a WAN port. If a Wi-Fi name and password are already saved, the service starts and the same Wi-Fi check can finish the handover in that run. When Wi-Fi is unavailable, the port stays WAN. A handover that has already finished is not repeated.

### Download and apply

If the installer is already on the booster, this downloads the current copy from GitHub and applies it:

```bash
./wifi-backhaul -U -y
```

`/root/wifi-backhaul -U -y` does the same thing.

The download address is `https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul`. When that file differs from the copy you started, the downloaded copy continues the update and keeps the same options, including `-y`, `-S`, `-s`, `-b` and `-i` if you passed them. When the download matches the copy you started, it prints `This installer is already the latest.` and continues. When the download fails, it prints `Could not download a newer installer. Applying this copy.` and continues with the copy you started. `-U` does not only apply the local file, and it cannot fetch a newer copy when GitHub cannot be reached.

The first time the script is not on the booster yet:

```bash
curl -skLo wifi-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul
chmod +x wifi-backhaul
./wifi-backhaul -U -y
```

The update does not restart the LAN. Refresh the browser when it finishes. If `-s` or `-S` copies new local Wi-Fi names, the local radios reload.

### What the update keeps

`-U` keeps:

- The upstream Wi-Fi name, password and saved radio lock (BSSID).
- The backhaul IP address.
- The booster's LAN IP address.
- The USB backup time, including a time you changed under **Management → Scheduled Tasks**.
- Chart visibility. An update does not change which cards are shown, including a summary chart and any individual card you have left visible.
- The Wi-Fi Booster card, if it was already enabled. You do not need to pass `-b` again.
- An enabled SSID synchronisation schedule. `./wifi-backhaul -Sr` removes that task.
- Firewall helpers, unused-service settings and the other dashboard cards. An update does not turn those services off again.

### Hourly Wi-Fi synchronisation during an update

An update keeps an enabled synchronisation task. You do not need to pass `-S` again for it to stay.

```bash
./wifi-backhaul -U -y
```

`./wifi-backhaul -U -S -y` keeps a custom schedule and turns the task on if it was missing or switched off. The five timing fields stay as you set them, and only the command is set back to `/root/dja-backhaul/sync-upstream-ssid`. The schedule returns to the default hourly entry only when that scheduled task is missing. Remove it with `./wifi-backhaul -Sr`.

### Keeping the pages after a tch-gui-unhide upgrade

To update tch-gui-unhide and put the booster pages back:

```bash
./tch-gui-unhide -U -y
```

To rebuild the web interface with the options already in use:

```bash
./tch-gui-unhide -dy -y
```

Either run restores the Wi-Fi Backhaul modifications and keeps the Wi-Fi Backhaul and Wi-Fi Booster pages. Unused dashboard cards stay removed, including Content Sharing, Mobile, Printer Sharing, Parental Controls and Relay Setup. `No such file or directory` messages for those removed cards stay suppressed.

**Important:** If the tch-gui-unhide `get` installer replaces `/root/tch-gui-unhide`, run Wi-Fi Backhaul again:

```bash
./wifi-backhaul -U -y
```

The hourly Wi-Fi check stays enabled if it is already enabled. This puts the Wi-Fi Backhaul pages back without clearing the saved upstream network, radio lock, backhaul address or LAN address.

## What the booster does

The booster stays on the main modem's LAN for management and for its own wireless clients. One 5 GHz interface is only the link back to the main modem. By default, the booster's local 2.4 GHz and 5 GHz Wi-Fi are separate from that upstream connection, with their own names and passwords.

The upstream link is an IPv4 pseudo-bridge (`relayd`). It is not a transparent Ethernet bridge, WDS, or a four-address link. The 5 GHz station is not added to the LAN bridge. Clients on the booster LAN keep their own MAC addresses there, and the main modem's Wi-Fi list shows the station rather than each of those clients. The station address and the booster's management address have to be in the same `/24`.

`-s` copies the main modem's local 2.4 GHz and 5 GHz names and passwords once. `-S` copies them and then keeps them in step on a schedule. Without `-s` or `-S`, those local networks are left as they are.

- The physical Wi-Fi button turns the local 2.4 GHz and local 5 GHz radios off and on. It does not drop the backhaul, and it does not turn the Online light red.
- Band steering is still available. When it is on, the two local radios share one Wi-Fi name. When it is off, they keep separate names.
- DNS shown for the Wi-Fi station is read from the upstream connection when it can be identified. The DNS fields are not edited here. Before the Wi-Fi check has passed, the station address script can already replace the booster's resolver list.
- After a successful handover, the old WAN port is an extra LAN port. Until that handover, it remains the WAN port and keeps its DHCP address, gateway and default route. The conversion is not reversed when Wi-Fi drops.
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

- **Broadband:** Hidden. Before handover, Ethernet WAN status is on the Internet Access and Local Network cards, not on a Broadband card.
- **Removed services:** Mobile, DNS, Firewall, xDSL, NAT Helpers and Relay Setup are removed from the dashboard and Management. The Mobile service is also disabled.
- **Hidden cards:** Eco Settings, Diagnostics, Packages, System Extras and Devices are hidden by default but can be re-enabled through Management.
- **Device Security:** Removed from the dashboard.
- **Diagnostics:** The TCP Dump tab is removed.

### Available dashboard cards

- **Internet Access:** While Wi-Fi is verified, this shows the upstream Wi-Fi network, signal strength and connection rate. Before that, when the default route is an Ethernet WAN port, the card code shows **Internet Access Available**, **WAN connected**, the WAN address and the gateway. The speed figures then use that Ethernet port. Seeing that WAN wording on a dashboard was not recorded as a separate check. Backhaul download and upload statistics are shown in the corner of the card.
- **Wi-Fi Backhaul:** Displays the active upstream connection, including its SSID, signal strength, connection rate, channel, channel width and uptime. It also allows you to scan for, connect to and manage wireless networks.
- **Wi-Fi Booster:** An optional card for reading the upstream BH SSID, password and beacon. It is only available when the installer has been run with `-b`.
- **Wi-Fi:** Displays the booster's local 2.4 GHz and 5 GHz wireless networks, with each band clearly separated.
- **Local Network:** Displays the booster's LAN IP address. While Wi-Fi is verified it also shows the Wi-Fi backhaul address and gateway. Before that, when Ethernet WAN holds the default route, the card code shows **WAN Connected**, **WAN IP** and that gateway. Seeing that WAN wording on a dashboard was not recorded as a separate check.
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

`./tch-gui-unhide -Cs` shows that summary chart. Run it before `pre-booster` and Wi-Fi Backhaul. Both of those then leave Backhaul Download and Backhaul Upload hidden. CPU and RAM stay as they already are.

An update with `./wifi-backhaul -U -y` does not change card visibility. A fresh install does the hiding when the summary chart is already on.

When the summary chart is not in use, a fresh install shows the CPU, RAM, Backhaul Download and Backhaul Upload cards. An update with `-U` leaves every card as it already is.

The installer does not turn the summary chart on for you. A summary chart you showed yourself in the dashboard is treated the same way as one left by `-Cs`. The saved setting is `web.card_Charts.hide=0`. That value does not, by itself, prove the `-Cs` command was used.

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

- **Schedule daily backup:** Enables an automatic backup of the configuration, environment and overlay. **Important:** This must be turned on before a backup task appears under **Management → Scheduled Tasks**. The task is not created by installing Wi-Fi Backhaul. Once enabled, the button changes to **Turn off daily backup**, which removes the task. Turning Enabled off, or deleting the row, also turns the backup off.
- **Hour and Minute:** Sets one time of day for that backup. For example, Hour `4` and Minute `8` is 4:08 AM. A leading zero, such as minute `08`, is stored as `8`. Saving a time does not turn a switched-off backup back on, and it does not replace a schedule that is not a single time of day.
- **Backup now:** Immediately creates a backup using the same process as the scheduled task.
- **Restore and reboot:** Restores the saved configuration and restarts the booster. A confirmation prompt is displayed before proceeding.

The installer does not choose the first clock time. Turning on **Schedule daily backup** runs `/root/mtd-backup -Cy`, which creates the task. Until a numeric time is saved, the Hour and Minute boxes show `4` and `0`. That is only the empty form.

Saving Hour and Minute writes this command when the card has to add the row:

```bash
/root/mtd-backup -d backups -ceoy
```

After the task exists, change a single daily time from the USB Backup card or from **Management → Scheduled Tasks**. Leave that command unchanged. `./wifi-backhaul -U` does not rewrite this task, so a time you selected is kept. If the row uses an advanced timing, such as every 30 minutes, or the row is switched off, saving Hour and Minute on the card leaves that row unchanged. Change an advanced timing under **Management → Scheduled Tasks**.

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

`./wifi-backhaul -y` leaves Ethernet WAN in place. The LAN address, subnet and DHCP server stay as `pre-booster` set them. While the port is still WAN, a linked cable obtains its DHCP address, gateway and default route from the modem's WAN service. The Ethernet WAN subnet has to be different from the booster LAN. The connection can drop later, only after Wi-Fi backhaul has been verified and the WAN port becomes a LAN port. Reconnect on the same LAN address. That conversion is not reversed when Wi-Fi drops.

Connect the wireless backhaul through the web interface. A management cable can stay in a LAN port. A WAN cable on another subnet has to come out before Wi-Fi verification finishes, because that jack then joins the LAN. After the handover has finished and the old WAN port is a LAN port, disconnect it and relocate the booster.

### wifi-backhaul

The main installer configures the device for wireless backhaul operation and provides optional features for Wi-Fi synchronisation and BH backhaul mode.

Standard installation:

```bash
./wifi-backhaul -y
```

| Option | Description |
|---|---|
| `-i` | Not required. The LAN address is already configured by `pre-booster`. |
| `-U` | Downloads the current installer from GitHub when it can, then updates while keeping the saved network settings, an enabled SSID synchronisation task, a custom schedule, and a task that has been switched off. |
| `-b` | Turns on experimental BH backhaul mode by enabling the Wi-Fi Booster card. The card can then read the upstream BH SSID. `-b` does not join that SSID by itself. |
| `-s` | Copies the main modem's 2.4 GHz and 5 GHz SSIDs and passwords once, including enabling band steering when it is enabled on the main modem. |
| `-S` | Turns on automatic Wi-Fi synchronisation and adds the hourly check under Management → Scheduled Tasks. The timing can be changed there. Running it again does not add a second task. |
| `-Sr` | Removes only that hourly check. The current Wi-Fi name, password and network settings stay as they are. Safe to run when the check is already absent. It cannot be combined with `-U`, `-S`, `-s`, `-b`, `-i` or `-t`. `./wifi-backhaul -U -Sr` is rejected. Run `./wifi-backhaul -Sr` on its own. `-y` may be included. |
| `-bs` | Combines `-b` and `-s`, enabling the Wi-Fi Booster card, copying Wi-Fi settings once and attempting to join the BH SSID. |
| `-bS` | Combines BH backhaul mode with automatic hourly Wi-Fi synchronisation. |
| `-y` | Automatically confirms installer prompts. |
| `-t` | Checks the packaged files and exits without proceeding with installation. |

### Additional notes

- **Preserving configuration:** Running `./wifi-backhaul -U -y` retains existing network settings, including the Wi-Fi Booster card if it was previously enabled.
- **Wi-Fi synchronisation:** The `-s` and `-S` options require an active connection to the main modem. If no connection is available, the Wi-Fi settings remain unchanged.
- **Scheduled synchronisation:** The task created by `-S` can be viewed and adjusted under **Management → Scheduled Tasks**. It is not listed until `-S` has been run. A later `./wifi-backhaul` or `./wifi-backhaul -U` keeps an enabled task, a custom timing, and a task that is switched off. It does not put a deleted task back. `./wifi-backhaul -Sr` removes only that task and leaves the current Wi-Fi name unchanged.
- **BH backhaul mode:** The `-b` option enables the Wi-Fi Booster card so it can read the BH SSID, password and beacon address from the upstream router. Joining that SSID is a later step.
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

## Troubleshooting

### Cannot access the booster after installation

The address to use is the LAN address you set with `pre-booster`, or the address already on the booster when you ran Wi-Fi Backhaul. The installer prints that address when it finishes. Installation itself leaves Ethernet WAN in place.

The management session can drop later, when Wi-Fi backhaul has been verified and the WAN port becomes a LAN port. Reconnect on the LAN address. A cable that was in the WAN port is then on the LAN. On an existing booster, use `./wifi-backhaul -U` so the update keeps the current network configuration.

If a handover fails, the previous Ethernet WAN configuration is restored. `restore-fresh-root` is the full way back to a clean rooted modem. It removes Wi-Fi Backhaul. It is not the next step for a failed Wi-Fi attempt.

### Ethernet WAN is connected but has no address

The port has to still be a WAN port. After a finished handover it is a LAN port, and a cable there does not start DHCP. While it is WAN, the modem's WAN service requests the address. Give the link a few seconds. The WAN network has to offer a DHCP lease. An address on the same `/24` as the booster LAN overlaps that LAN and is not a usable Ethernet WAN.

### Ethernet WAN has an address but no internet

Confirm the default route points at the WAN gateway on the WAN port. A Wi-Fi default route is preferred while the station is up, so an ordinary ping can miss the Ethernet WAN path. The WAN gateway should answer when the ping is sent out the WAN port. The upstream network also has to route to the internet. WAN masquerade has to still be enabled for a computer on a LAN port. That computer needs a lease from the booster, with the booster as its gateway, before the handover turns the booster's DHCP server off.

### Internet works but the cards still say Wi-Fi is disconnected

Internet Access and Local Network show Ethernet WAN when the default route is an Ethernet port and Wi-Fi is not verified. The Broadband card stays hidden and is not that display. The card files have to be the ones from this installer, and the web server has to load them. A dashboard that still shows only the Wi-Fi wording after a refresh is still on the previous card files. The new WAN wording itself has not been captured on a screenshot.

### Wi-Fi connects but the handover does not run

The port moves only after the station checks pass, including a gateway ping from the station address. A saved BSSID that does not match, a station address outside the LAN `/24`, or a pause left by an earlier failed attempt stops the move and leaves Ethernet WAN in place. Connect on the Wi-Fi Backhaul card clears that pause and tries again. An existing success marker means the port was already converted and the move is not repeated.

### The handover watchdog does not start

The watchdog is started before the port moves. If it cannot start, the handover stops and Ethernet WAN stays as it is. The pending marker is not left behind by that failed start. On the spare, the conversion at 19:59 completed with this watchdog. Skipping it is not part of normal operation.

### Names fail before the handover while addresses still answer

The station address script can replace the booster's DNS servers as soon as the station has an address, which is before the Wi-Fi check. Pings to internet addresses can still use Ethernet WAN. Name lookups then use the new servers, which may be reachable only through the Wi-Fi network. Public DNS addresses can still answer through Ethernet WAN.

### The former WAN port no longer works as WAN

That is the finished handover. `eth4` is in the LAN bridge, the WAN protocol is `none`, and `/root/dja-backhaul/wan-as-lan` is present. Wi-Fi is the upstream path. Plugging a cable into that jack does not bring Ethernet WAN back. Putting the port back means restoring the saved WAN configuration. A cable from another network must stay out of that jack while it is in the LAN bridge.

### Wi-Fi Backhaul cannot connect

In the Wi-Fi Backhaul card, check the upstream name and type the Wi-Fi password from the main modem. The network name is not the password.

The same card shows signal strength after a scan. The booster's 5 GHz backhaul uses the same channel as the main modem.

Connecting saves a lock to the radio (BSSID) that was joined. That lock can stop the booster joining a different access point that uses the same name. Disconnect clears the active lock. Connecting to another network replaces it. Forget Network removes the saved network.

### Automatic SSID synchronisation is not working

The main modem has to be connected and reachable. If it is not, the copy does nothing and the local names stay as they are.

Under **Management → Scheduled Tasks**, confirm the task is there and Enabled. The command should be `/root/dja-backhaul/sync-upstream-ssid`. The task exists only after `-S`. A later update does not remove it. `./wifi-backhaul -Sr` removes only that task and leaves the current Wi-Fi name, password and network settings unchanged. Put it back with:

```bash
./wifi-backhaul -U -S -y
```

If the first copy did not run because the link was down, the scheduled task tries again on its next run. You can also use **Mirror Main Wi-Fi SSID** → **Copy** on the Wi-Fi page once the link is up. That is the same one-time copy as `-s`.

### BH backhaul mode is not connecting

Turning on the Wi-Fi Booster card only makes the card available. It does not join the BH SSID by itself.

Collect the details first (**Collect main backhaul**, or `main-backhaul` on the main modem), then choose **Connect** on the **Main backhaul** row in the Wi-Fi Backhaul card. An attempt started by `-bs` or `-bS` waits while the visible link is down. It stops, and leaves the current network in place, when the BH beacon is not in the scan. The password it uses is the BH SSID password, not the visible Wi-Fi password.

Collection of those details is described for firmware `20.3.c.0389`. Upstream compatibility, including the Gen 3 results so far, is covered under [Enable the Wi-Fi Booster card](#3-enable-the-wi-fi-booster-card).

If joining the BH network drops internet, use Forget Network on that entry and connect again to the visible Wi-Fi network.

### USB backup task is missing

Turn on **Schedule daily backup** in the USB Backup card first. The row is not added by the installer alone. Then look under **Management → Scheduled Tasks**. A USB drive has to be plugged in before a backup can be written.

### Dashboard cards have reappeared

A summary chart is `web.card_Charts.hide=0`. That is what `./tch-gui-unhide -Cs` leaves behind. When it is already on, `pre-booster` and a fresh Wi-Fi Backhaul install hide Backhaul Download and Backhaul Upload. They do not turn the summary chart on, and they do not change CPU or RAM. An update does not change card visibility.

If that summary chart is still the one on screen, run Wi-Fi Backhaul again. Use `-U` when the booster is already installed. The summary chart and any individual card you have left visible stay as they are. An enabled hourly Wi-Fi check stays enabled.

If a later `tch-gui-unhide` run turned the summary chart off, Wi-Fi Backhaul will not switch it back on. Run `./tch-gui-unhide` with `-Cs` again, then run Wi-Fi Backhaul with `-U`.

## Compatibility and known limitations

- **Hardware:** This is for a rooted Telstra DJA0231. The acknowledgements describe that as Telstra Gen 2 hardware. Other models are not covered here.
- **Firmware:** Reading the BH SSID is identified on `20.3.c.0389`. The Ethernet WAN checks in this README were made on an already installed spare running `20.3.c.0501-MR22.1-RA`. A fresh install with the WAN cable already connected was not part of that check. Do not treat every firmware release as supported.
- **Root:** The modem must already be rooted. A factory reset is only safe when you know that firmware keeps root. `restore-fresh-root` returns a clean rooted configuration and still leaves the modem rooted. It is not stock Telstra firmware.
- **BH backhaul mode:** Optional and experimental. `-b` adds the Wi-Fi Booster card so the booster can use the upstream BH SSID instead of a normal 5 GHz SSID. Joining is a separate step, or an attempt started by `-bs` or `-bS`. Initial testing suggests a Telstra Smart Modem Gen 3 can work as the upstream router. Other upstream devices are not confirmed. See [Enable the Wi-Fi Booster card](#3-enable-the-wi-fi-booster-card).
- **Local Wi-Fi:** Independent of the upstream link unless you use `-s` or `-S`.
- **Scheduled tasks:** Hourly Wi-Fi synchronisation stays as it already is. `-S` turns it on. `-Sr` turns it off. USB backup scheduling appears only after **Schedule daily backup** is turned on. Running `./wifi-backhaul` again offers saved settings as defaults. Press Enter to keep one. A saved password is not displayed.
