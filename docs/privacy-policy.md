# Privacy Policy — Remote TV 2026

- **Effective date:** 24 September 2026
- **App:** Remote TV 2026 (iOS and Android)
- **Developer:** Thaer Mosa — <https://thaerm.github.io/>

Remote TV 2026 is a remote control and casting app for compatible smart TVs
and streaming devices on your home network. It is built to work locally:
it talks to your TV over your Wi-Fi network and does not send your
information to the developer or to anyone else.

## Summary

- **No account.** You never sign up or log in.
- **No data collected by the developer.** The app has no server, and
  contains no analytics, advertising, tracking, or crash-reporting
  software.
- **Local network only.** The app finds and controls TVs on the Wi-Fi
  network your phone is connected to.
- **Pairing credentials stay on your phone**, in the system's secure
  storage (iOS Keychain / Android Keystore). They are used only to talk to
  the TV they belong to.
- **Pairing codes are never stored or logged.**

## Information the app handles

### Local network discovery

To show you the TVs you can control, the app looks for devices on your
local network using standard discovery protocols: Bonjour / mDNS (for
Android TV / Google TV and Google Cast devices) and, where the phone's
operating system allows it, SSDP / UPnP (for Roku, LG, Samsung, and DLNA
devices). If you use **Add TV by IP address**, the app contacts only the
address you enter, on the network ports those TVs use.

On iOS, the system asks your permission ("Local Network") before the app
can do this. You can change the permission at any time in the iOS Settings
app.

### Information about your TVs

Discovery answers contain information your TVs publish on your network:
device name (for example "Family room TV"), model, network (IP) address and
port, and a device identifier such as a serial number or UPnP ID. The app
uses this to list and connect to your TVs.

For Android TV / Google TV devices you have paired, the app remembers the
device's identifier, name, last known network address, and the time you
last connected, so it can reconnect without pairing again. This is stored
only on your phone.

### Pairing credentials

Some TVs require the app to pair once before they accept commands:

| TV | What the app stores | Where |
|---|---|---|
| Android TV / Google TV | A certificate and private key the app generates on your phone for that TV | iOS Keychain / Android Keystore-backed storage |
| LG webOS | The client key the TV issues when you accept the pairing prompt | iOS Keychain / Android Keystore-backed storage |
| Samsung (Tizen) | The token the TV issues when you allow the connection | iOS Keychain / Android Keystore-backed storage |

These credentials are only ever sent to the TV they belong to, as part of
connecting to it. The private key never leaves your phone. The 6-character
code an Android TV displays during pairing is used once to complete
pairing; it is not stored, and it is never written to logs.

### What you send to your TV

When you use the app, it sends your TV the commands you choose (for
example D-pad, volume, Home), text you type with the keyboard feature, and
requests to open supported apps. When you cast a link, the app sends the
link (and an optional title you enter) to the TV or media device; the
device downloads the media directly from that address. The app does not
upload, download, or store the media itself.

### Diagnostic logs

The app writes technical log lines (for example "discovery completed, 2
devices found") to your phone's system log to help diagnose connection
problems. These may include TV names and local network addresses. They
never include pairing codes, keys, certificates, or tokens. The logs stay
on your phone; the app never sends them anywhere. They are visible only to
someone with developer tools connected to your phone.

## What the app does not do

- It does not collect, sell, or share personal information.
- It does not use your location, contacts, photos, camera, microphone, or
  Bluetooth.
- It does not track you across apps or websites and shows no ads.
- It does not include analytics or crash-reporting services.
- It does not send anything to the developer.

## Links you open

The About and Settings screens link to this policy, the support page, the
developer's website, and GitHub. These open in your web browser and are
covered by the privacy practices of those websites (for example GitHub
Pages), not by the app.

## Third-party components

The app is built with Flutter and open-source libraries (listed under
**Settings → About → Open Source Licenses**). They provide features such
as secure storage, local settings, opening links, reading the app version,
and network discovery. None of them collect or transmit your data. The app
does not include any third-party SDK that sends data to its provider.

## Data retention and deletion

Everything the app stores is on your phone:

- **Forget a paired Android TV** in the Devices screen to delete its
  stored details and pairing credentials.
- **Uninstalling the app** removes its data on Android. On iOS, the
  system may keep Keychain items (pairing credentials) after the app is
  deleted; they can only be read by this app and are removed when you
  erase the device or reset its Keychain.

Because the developer holds no data about you, there is nothing to request
from or delete on the developer's side.

## Security

Pairing credentials are kept in the operating system's secure storage.
Android TV connections use TLS with the certificate created during pairing.
Other TVs use the protocol that TV supports on your local network; some
older TV protocols are not encrypted, which is why the app works only on
the network your phone is connected to.

## Children's privacy

The app is not directed to children and does not knowingly collect any
personal information from anyone, including children under 13 (or the
equivalent minimum age in your country).

## Changes to this policy

If this policy changes, the updated version will be published at the same
address with a new effective date. Material changes will also be noted in
the app's release notes.

## Contact

- **Developer:** Thaer Mosa
- **Website:** <https://thaerm.github.io/>
- **GitHub:** <https://github.com/ThaerM>

---

Remote TV 2026 is not affiliated with or endorsed by Google, Roku, LG,
Samsung, or any other TV or streaming-device manufacturer. Product names
are trademarks of their respective owners.
