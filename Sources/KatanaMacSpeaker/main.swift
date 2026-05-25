import CoreAudio
import Foundation

let executableName = "katana-macspeaker"
let systemObject = AudioObjectID(kAudioObjectSystemObject)

struct Arguments {
    var targetName = "KATANA"
    var channels = (left: UInt32(3), right: UInt32(4))
    var listOnly = false
    var setAsDefault = true
}

func statusText(_ status: OSStatus) -> String {
    if status == noErr { return "noErr" }
    return "OSStatus \(status)"
}

func getStringProperty(_ objectID: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var value: CFString?
    var size = UInt32(MemoryLayout<CFString?>.size)
    let status = withUnsafeMutablePointer(to: &value) { pointer in
        AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, pointer)
    }
    return status == noErr ? value as String? : nil
}

func getDevices() throws -> [AudioDeviceID] {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    var status = AudioObjectGetPropertyDataSize(systemObject, &address, 0, nil, &size)
    guard status == noErr else {
        throw NSError(
            domain: "CoreAudio",
            code: Int(status),
            userInfo: [NSLocalizedDescriptionKey: "Could not read device list size: \(statusText(status))"]
        )
    }

    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    var devices = [AudioDeviceID](repeating: 0, count: count)
    status = devices.withUnsafeMutableBufferPointer { pointer in
        AudioObjectGetPropertyData(systemObject, &address, 0, nil, &size, pointer.baseAddress!)
    }
    guard status == noErr else {
        throw NSError(
            domain: "CoreAudio",
            code: Int(status),
            userInfo: [NSLocalizedDescriptionKey: "Could not read devices: \(statusText(status))"]
        )
    }
    return devices
}

func preferredStereoChannels(_ device: AudioDeviceID) -> (UInt32, UInt32)? {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    var channels = [UInt32](repeating: 0, count: 2)
    var size = UInt32(channels.count * MemoryLayout<UInt32>.size)
    let status = channels.withUnsafeMutableBufferPointer { pointer in
        AudioObjectGetPropertyData(device, &address, 0, nil, &size, pointer.baseAddress!)
    }
    return status == noErr ? (channels[0], channels[1]) : nil
}

func setPreferredStereoChannels(_ device: AudioDeviceID, left: UInt32, right: UInt32) throws {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    var settable = DarwinBoolean(false)
    let settableStatus = AudioObjectIsPropertySettable(device, &address, &settable)
    guard settableStatus == noErr, settable.boolValue else {
        throw NSError(
            domain: "CoreAudio",
            code: Int(settableStatus),
            userInfo: [NSLocalizedDescriptionKey: "Preferred stereo channels are not settable on this device"]
        )
    }

    var channels = [left, right]
    let size = UInt32(channels.count * MemoryLayout<UInt32>.size)
    let status = channels.withUnsafeMutableBufferPointer { pointer in
        AudioObjectSetPropertyData(device, &address, 0, nil, size, pointer.baseAddress!)
    }
    guard status == noErr else {
        throw NSError(
            domain: "CoreAudio",
            code: Int(status),
            userInfo: [NSLocalizedDescriptionKey: "Could not set preferred stereo channels: \(statusText(status))"]
        )
    }
}

func setDefaultOutput(_ device: AudioDeviceID) throws {
    var outputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var systemOutputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var selectedDevice = device
    let size = UInt32(MemoryLayout<AudioDeviceID>.size)

    var status = AudioObjectSetPropertyData(systemObject, &outputAddress, 0, nil, size, &selectedDevice)
    guard status == noErr else {
        throw NSError(
            domain: "CoreAudio",
            code: Int(status),
            userInfo: [NSLocalizedDescriptionKey: "Could not set default output: \(statusText(status))"]
        )
    }

    status = AudioObjectSetPropertyData(systemObject, &systemOutputAddress, 0, nil, size, &selectedDevice)
    guard status == noErr else {
        throw NSError(
            domain: "CoreAudio",
            code: Int(status),
            userInfo: [NSLocalizedDescriptionKey: "Could not set default system output: \(statusText(status))"]
        )
    }
}

func usage() {
    print("""
    Usage:
      \(executableName)                      Set BOSS Katana stereo output to USB channels 3/4
      \(executableName) --reset              Set BOSS Katana stereo output back to USB channels 1/2
      \(executableName) --list               List output devices and preferred stereo channels

    Options:
      --device NAME             Match a different BOSS output device name
      --channels LEFT RIGHT     Set a custom preferred stereo channel pair
      --no-default              Do not make the matched device the macOS default output
      -h, --help                Show this help

    Examples:
      \(executableName)
      \(executableName) --device KATANA3
      \(executableName) --channels 3 4
      \(executableName) --reset
    """)
}

func parseArguments(_ args: [String]) throws -> Arguments {
    var parsed = Arguments()
    var index = 0

    while index < args.count {
        switch args[index] {
        case "-h", "--help":
            usage()
            exit(0)
        case "--list":
            parsed.listOnly = true
        case "--reset":
            parsed.channels = (left: 1, right: 2)
        case "--no-default":
            parsed.setAsDefault = false
        case "--device":
            guard args.indices.contains(index + 1) else {
                throw NSError(domain: executableName, code: 2, userInfo: [NSLocalizedDescriptionKey: "--device requires a name"])
            }
            parsed.targetName = args[index + 1]
            index += 1
        case "--channels":
            guard args.indices.contains(index + 2),
                  let left = UInt32(args[index + 1]),
                  let right = UInt32(args[index + 2]) else {
                throw NSError(domain: executableName, code: 2, userInfo: [NSLocalizedDescriptionKey: "--channels requires two positive integers"])
            }
            parsed.channels = (left: left, right: right)
            index += 2
        default:
            throw NSError(domain: executableName, code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown argument: \(args[index])"])
        }
        index += 1
    }

    return parsed
}

func matchingDevice(named targetName: String, in devices: [AudioDeviceID]) -> AudioDeviceID? {
    let target = targetName.lowercased()

    return devices.first(where: { device in
        let name = (getStringProperty(device, kAudioObjectPropertyName) ?? "").lowercased()
        let manufacturer = (getStringProperty(device, kAudioObjectPropertyManufacturer) ?? "").lowercased()
        return name == target && manufacturer.contains("boss") && preferredStereoChannels(device) != nil
    }) ?? devices.first(where: { device in
        let name = (getStringProperty(device, kAudioObjectPropertyName) ?? "").lowercased()
        let manufacturer = (getStringProperty(device, kAudioObjectPropertyManufacturer) ?? "").lowercased()
        return name.contains(target) && manufacturer.contains("boss") && preferredStereoChannels(device) != nil
    })
}

do {
    let arguments = try parseArguments(Array(CommandLine.arguments.dropFirst()))
    let devices = try getDevices()

    if arguments.listOnly {
        for device in devices {
            guard let stereo = preferredStereoChannels(device) else { continue }
            let name = getStringProperty(device, kAudioObjectPropertyName) ?? "(unnamed)"
            let manufacturer = getStringProperty(device, kAudioObjectPropertyManufacturer) ?? "(unknown)"
            print("\(name) [\(manufacturer)] preferred stereo: \(stereo.0)/\(stereo.1)")
        }
        exit(0)
    }

    guard let device = matchingDevice(named: arguments.targetName, in: devices) else {
        throw NSError(
            domain: executableName,
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not find a BOSS output device matching '\(arguments.targetName)'. Run: \(executableName) --list"]
        )
    }

    let name = getStringProperty(device, kAudioObjectPropertyName) ?? arguments.targetName
    try setPreferredStereoChannels(device, left: arguments.channels.left, right: arguments.channels.right)

    if arguments.setAsDefault {
        try setDefaultOutput(device)
    }

    let stereo = preferredStereoChannels(device)
    let defaultText = arguments.setAsDefault ? " and made it the default output" : ""
    print("Set \(name) preferred stereo output to \(stereo?.0 ?? arguments.channels.left)/\(stereo?.1 ?? arguments.channels.right)\(defaultText).")
} catch {
    fputs("\(executableName): \(error.localizedDescription)\n", stderr)
    exit(1)
}
