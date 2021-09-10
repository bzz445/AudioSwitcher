//
//  AudioService.swift
//  AudioSwitcher
//
//  Created by Pavel Morozov on 06.09.2021.
//

import Foundation
import CoreAudio

struct AudioAddress {
    static var outputDevice = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster)

    static var inputDevice = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster)
    
    static var devices = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                    mScope: kAudioObjectPropertyScopeGlobal,
                                                    mElement: kAudioObjectPropertyElementMaster)

    static var deviceName = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceNameCFString,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster)

    static var streamConfiguration = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreamConfiguration,
        mScope: kAudioDevicePropertyScopeInput,
        mElement: kAudioObjectPropertyElementMaster)
}

struct AudioDevice {
    var id: AudioDeviceID
    var hasOutput: Bool
    var selected: Bool
    var name: String
}

class AudioService {
    static let shared: AudioService = {
        let instance = AudioService()
        return instance
    }()
    
    var selectedOutputDeviceID: AudioDeviceID? {
        didSet {
            if var id = self.selectedOutputDeviceID {
                self.setOutputDevice(id: &id)
            }
        }
    }

    var selectedInputDeviceID: AudioDeviceID? {
        didSet {
            if var id = self.selectedInputDeviceID {
                self.setInputDevice(id: &id)
            }
        }
    }
    
    private var devicesListener: AudioObjectPropertyListenerProc = { _, _, _, _ in
        NotificationCenter.default.post(name: Notification.Name("AudioDevicesDidChange"), object: nil)
        return 0
    }
    
    private var outputListener: AudioObjectPropertyListenerProc = { _, _, _, _ in
        NotificationCenter.default.post(name: Notification.Name("AudioOutputDeviceDidChange"), object: nil)
        return 0
    }

    private var inputListener: AudioObjectPropertyListenerProc = { _, _, _, _ in
        NotificationCenter.default.post(name: Notification.Name("AudioInputDeviceDidChange"), object: nil)
        return 0
    }
    
    private init() {
        print("bzz init")
    }
    
    deinit {
        print("bzz deinit")
    }
    
    func start() {
        print("bzz start")
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.devices, devicesListener, nil)
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, outputListener, nil)
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.inputDevice, inputListener, nil)
    }
    
    func stop() {
        print("bzz stop")
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.devices, devicesListener, nil)
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, outputListener, nil)
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.inputDevice, inputListener, nil)
    }
    
    func getDevices() -> [AudioDevice] {
        let objectID = AudioObjectID(kAudioObjectSystemObject)
        var address = AudioAddress.devices
        var size: UInt32 = 0
        AudioObjectGetPropertyDataSize(objectID, &address, 0, nil, &size)
        
        var deviceIDs: [AudioDeviceID] = {
            var deviceIDs = [AudioDeviceID]()
            for _ in 0..<Int(size) / MemoryLayout<AudioDeviceID>.size {
                deviceIDs.append(AudioDeviceID())
            }
            return deviceIDs
        }()
        
        AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, &deviceIDs)
        
        var devices: [AudioDevice] = []
        for id in deviceIDs {
            let name: String = {
                var name: CFString = "" as CFString
                var address = AudioAddress.deviceName
                var size: UInt32 = 0
                AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
                AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name)
                return name as String
            }()
            
            let hasOutput: Bool = {
                var address = AudioAddress.streamConfiguration
                var size: UInt32 = 0
                AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
                let bufferList = AudioBufferList.allocate(maximumBuffers: Int(size))
                AudioObjectGetPropertyData(id, &address, 0, nil, &size, bufferList.unsafeMutablePointer)
                let channelCount: Int = {
                    var count = 0
                    for index in 0 ..< Int(bufferList.unsafeMutablePointer.pointee.mNumberBuffers) {
                        count += Int(bufferList[index].mNumberChannels)
                    }
                    return count
                }()
                
                free(bufferList.unsafeMutablePointer)
                return (channelCount > 0) ? false : true
            }()
            
            var selected = false
            
            if hasOutput {
                selected = getSelectedOutputDevice() == id
            } else {
                selected = getSelectedInputDevice() == id
            }
            
            devices.append(AudioDevice(id: id, hasOutput: hasOutput, selected: selected, name: name))
        }
        
        return devices
    }
    
    func getSelectedInputDevice() -> AudioObjectID? {
        var deviceId = AudioDeviceID(0)
        var deviceSize = UInt32(MemoryLayout.size(ofValue: deviceId))
        var address = AudioAddress.inputDevice
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &deviceSize, &deviceId);
        return deviceId
    }
    
    func getSelectedOutputDevice() -> AudioObjectID? {
        var deviceId = AudioDeviceID(0)
        var deviceSize = UInt32(MemoryLayout.size(ofValue: deviceId))
        var address = AudioAddress.outputDevice
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &deviceSize, &deviceId);
        return deviceId
    }
    
    private func setOutputDevice(id: inout AudioDeviceID) {
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &id)
    }

    private func setInputDevice(id: inout AudioDeviceID) {
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.inputDevice, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &id)
    }
}

extension AudioService: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
