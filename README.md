# DJA0231 Wi-Fi backhaul

This turns a rooted Telstra DJA0231 into a Wi-Fi booster. It joins the main modem over Wi-Fi and keeps its own 2.4 GHz and 5 GHz networks for nearby clients. It is not the EasyMesh `bridged-booster` script. That one expects a cable back to the main modem. This one uses Wi-Fi as the backhaul.

The upstream network name and password are not in this download. After the booster boots, choose that network in the Wi-Fi Backhaul card.

## Download and install

Run this on the booster, after root, de-telstra, and tch-gui-unhide:

```sh
curl -skLo wifi-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul
chmod +x wifi-backhaul
./wifi-backhaul -i 192.168.100.2 -y
```

`-i` is this booster's own address, the one you type in a browser. `192.168.100.2` is the address on a `192.168.100.0` network. On another network, pass that network's address instead. The script restarts services and does not reboot. Open the new address when it finishes.

## Fresh setup

`192.168.19.254` in older notes was only an example. Use the address for the network you are actually on.

```sh
./reset-to-factory-defaults-with-root -I 192.168.100.2 -c
curl -skL https://raw.githubusercontent.com/seud0nym/tch-gui-unhide/master/get | sh -s -- -g
./de-telstra -S -M -ma -h DJA0231-Booster -d DJA0231-Booster -y
./tch-gui-unhide -hn -dy -Cs -tc -a5 -y
curl -skLo wifi-backhaul https://raw.githubusercontent.com/kavie87/wifi-backhaul/main/wifi-backhaul
chmod +x wifi-backhaul
./wifi-backhaul -i 192.168.100.2 -y
```

When it finishes:

1. Open `http://192.168.100.2/`
2. Open the Wi-Fi Backhaul card and choose the main modem's Wi-Fi.
3. The backhaul address starts on DHCP. Set a static address in that same card if you want one.

Running `./wifi-backhaul` again keeps an upstream network and a backhaul address that are already saved.

## Update an existing booster

```sh
./wifi-backhaul -U -y
```

This downloads the latest installer and applies it. The upstream Wi-Fi, the saved radio lock, the backhaul address, this booster's LAN address, and the USB backup time stay as they are. It does not reboot, and the backhaul link stays up. Refresh the browser when it finishes.

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

That upgrade rewrites the web pages, then puts the booster pages back. If you run the tch-gui-unhide `get` command again and it replaces `/root/tch-gui-unhide`, run `./wifi-backhaul -U -y` once more so later upgrades keep the pages.

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
- The USB column lists a plugged-in stick: product name, manufacturer, and port.
- DECT is not shown.
- The Wi-Fi details on the left are the local networks, not the upstream network.

## Dashboard cards

The Advanced dashboard keeps the cards that matter on a booster.

- Broadband is not shown.
- Internet Access shows the upstream network, signal, and rate.
- Wi-Fi Backhaul shows the upstream name, signal, rate, channel, width, and uptime. The scan list is titled Available Networks, and its columns line up with Current Backhaul. Connecting to a network saves a lock to the radio it joined. Disconnect drops that lock. A different network drops the old lock and saves the new radio after it connects. Reconnect saves the radio it joins.
- Wi-Fi shows the local 2.4 GHz and 5 GHz names, with a gap between the two bands.
- Local Network shows this booster's address, and the backhaul address and gateway while the backhaul link is up.
- USB Backup is the USB backup and restore page described below.
- Management is where card names are shown and cards are switched on or off. The backup card is labelled USB.
- Diagnostics no longer has a TCP Dump tab.

Backhaul download and upload graph cards stay hidden. The charts card stays available.

## Local Network page

- Local Network Subnet is shown and cannot be edited.
- IPv6 is a read-only On or Off. It follows router advertisements from the main modem. It does not turn IPv6 on for the booster.
- Local Domain Name and the booster IPv4 address can be changed. Saving the address changes this booster's LAN address.
- Guest interfaces are not listed.

## Wi-Fi page

- The tabs are the local 2.4 GHz and local 5 GHz networks.
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

```text
./wifi-backhaul -i 192.168.100.2 -y
```

| Option | Effect |
| --- | --- |
| `-i` | This booster's LAN address |
| `-U` | Update an existing booster and keep its saved settings. Does not reboot |
| `-y` | Do not ask for confirmation |
| `-n` | Accepted. A new install does not reboot |
| `-t` | Check the packaged files and exit |

## Put the booster back

`restore-fresh-root` removes the Wi-Fi booster and returns the modem to a freshly rooted setup, the same path as the [tch-gui-unhide wiki](https://github.com/seud0nym/tch-gui-unhide/wiki):

1. `reset-to-factory-defaults-with-root` keeps root and the current SSH key, and turns CWMP off for the first boot.
2. `de-telstra -A`
3. A clean `tch-gui-unhide`, without the booster pages.

```sh
./restore-fresh-root -I 192.168.100.2 -y
```

The root password is set back to `root`. The upstream network and the booster pages are not kept. This is not the USB backup restore. That restore puts the booster setup back.

After the reboot it is a normal modem again. Plug a computer into a LAN port to open the address passed with `-I`. If a USB stick is already inserted, the script copies `de-telstra` and a clean unhide onto it and uses those after the reboot. With no USB stick, plug the WAN port into the main modem so those two scripts can download. The result is written to `/root/fresh-root.log`.

Leave `-I` off to use the factory LAN address. `-i` keeps the address the booster has now.
