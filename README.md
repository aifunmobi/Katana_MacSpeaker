# Katana_MacSpeaker

Katana_MacSpeaker is a small macOS utility for BOSS Katana owners who want normal Mac audio to come out of the amp speaker over USB.

It works by changing the CoreAudio preferred stereo output pair for the real BOSS Katana device from USB channels `1/2` to USB channels `3/4`, then making that device the default macOS output.

This is an unofficial workaround. BOSS/Roland documentation treats Katana USB audio primarily as a recording and reamping interface, not as a normal computer speaker. On some Katana models, USB output `3/4` is the reamp path and can be heard through the amp speaker. This utility only automates the macOS channel mapping needed to use that path.

## What It Can Do

- Find a real BOSS Katana CoreAudio output device, such as `KATANA3 [BOSS]`.
- Set the preferred macOS stereo pair to USB channels `3/4`.
- Make the Katana the default macOS output device.
- Reset the preferred stereo pair back to USB channels `1/2`.
- List output devices and their current preferred stereo channel pair.
- Install an optional double-clickable `boss.command` launcher on your Desktop.

## What It Cannot Do

- It cannot change BOSS firmware or the Katana USB driver.
- It cannot make ordinary USB channels `1/2` play through the speaker if the amp firmware does not route them there.
- It cannot make a two-channel-only virtual device expose channels `3/4`.
- It cannot route through apps like eqMac if they wrap the Katana as a two-channel output.
- It cannot guarantee clean hi-fi playback. Audio sent to USB `3/4` may pass through the amp's guitar/reamp path, gain, effects, EQ, channel volume, and master volume.
- It cannot unmute the speaker if headphones or `PHONES/REC OUT` are connected on models that mute the internal speaker.
- It is not an official BOSS/Roland tool.

## Compatibility

Tested with:

- macOS
- BOSS Katana Gen 3 showing up as `KATANA3`
- BOSS macOS USB driver installed
- CoreAudio reporting the real Katana device as a 4-output-channel device

Likely to work with:

- BOSS Katana models that expose 4 USB output channels on macOS
- Models where USB output `3/4` routes to the amp/reamp path

Likely not to work with:

- Devices that expose only stereo USB output
- `KATANA:GO`, which Roland documents as stereo-only USB audio
- Virtual or wrapper devices that expose only 2 channels, including `KATANA3 (eqMac)`
- Bluetooth audio paths

## Install

### Ready-to-Run Download

The repo includes prebuilt files in `dist/`:

```text
dist/katana-macspeaker
dist/boss.command
```

To use the checked-in build, download the repo, keep both files in the same folder, then double-click `boss.command`. If you prefer to rebuild the checked-in files yourself, run `make dist`.

If macOS blocks the downloaded command or binary, remove quarantine in Terminal:

```sh
xattr -dr com.apple.quarantine dist/katana-macspeaker dist/boss.command
chmod +x dist/katana-macspeaker dist/boss.command
```

Then double-click `dist/boss.command` again.

### Build From Source

You need the macOS command line tools or Xcode so `swiftc` is available.

```sh
git clone https://github.com/aifunmobi/Katana_MacSpeaker.git
cd Katana_MacSpeaker
make install
```

This installs:

```text
~/.local/bin/katana-macspeaker
```

Make sure `~/.local/bin` is on your shell `PATH` if you want to run `katana-macspeaker` without typing the full path.

## Use

Turn on the Katana, connect USB, then run:

```sh
katana-macspeaker
```

Or, if `~/.local/bin` is not on your `PATH`:

```sh
~/.local/bin/katana-macspeaker
```

Expected output looks like:

```text
Set KATANA3 preferred stereo output to 3/4 and made it the default output.
```

To inspect devices:

```sh
katana-macspeaker --list
```

To undo the workaround:

```sh
katana-macspeaker --reset
```

To target a specific device name:

```sh
katana-macspeaker --device KATANA3
```

To set a custom stereo channel pair:

```sh
katana-macspeaker --channels 3 4
```

## Desktop Launcher

To install a double-clickable `boss.command` file on your Desktop:

```sh
make desktop-launcher
```

The launcher does three things:

- Quits eqMac if it is running.
- Waits for a real `KATANA ... [BOSS]` output device.
- Runs `katana-macspeaker` and plays a short macOS confirmation sound.

## eqMac Note

eqMac can be useful, but it may create a virtual output device such as:

```text
KATANA3 (eqMac)
```

On the tested system, that virtual device exposed only 2 output channels. The real BOSS device exposed 4 output channels. Since this workaround needs channels `3/4`, quit eqMac before running Katana_MacSpeaker.

If you need EQ and channel routing at the same time, use a routing tool that can explicitly send stereo audio to hardware outputs `3/4`.

## Troubleshooting

If you see "Could not find a BOSS output device":

- Turn the amp on.
- Check the USB cable supports data, not just charging.
- Install the correct BOSS USB driver for your macOS version.
- Open macOS Sound settings and confirm the Katana appears.
- Run `katana-macspeaker --list` and look for a device with `[BOSS]`.

If the command succeeds but you hear nothing:

- Turn down Mac and amp volume first, then bring them up gradually.
- Select a clean Katana channel.
- Turn gain low and effects off.
- Raise channel volume and master volume.
- Make sure nothing is plugged into a jack that mutes the speaker.
- Quit eqMac or other virtual audio routers.
- Confirm the real BOSS device has 4 output channels in Audio MIDI Setup.

If audio sounds distorted:

- Lower Mac volume.
- Lower Katana gain.
- Use a clean channel.
- Turn off booster, modulation, delay, reverb, and EQ.

## Build Without Installing

```sh
make build
.build/release/katana-macspeaker --help
```

## Uninstall

```sh
make uninstall
rm -f ~/Desktop/boss.command
```

## References

- Roland support: KATANA MkII USB inputs and outputs on macOS: https://support.roland.com/hc/en-us/articles/14930089693083-KATANA-MkII-Amp-Series-What-do-the-different-USB-inputs-mean-in-my-DAW
- Roland support: KATANA MkI/MkII USB reamping uses output `3/4` on Mac: https://support.roland.com/hc/en-us/articles/15361124397723/
- Roland support: KATANA MkII USB monitoring note: https://support.roland.com/hc/en-us/articles/14137949569307-KATANA-MkII-Amp-Series-Recording-via-USB-into-your-DAW
- BOSS/Roland KATANA Gen 3 reference manual: https://static.roland.com/assets/media/pdf/KTN3_reference_eng02_W.pdf

## License

MIT
