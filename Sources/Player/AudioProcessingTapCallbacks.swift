//
//  AudioProcessingTapCallbacks.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/11/27.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import MediaToolbox
import CoreAudio


class AVAudioTapProcessorContext<T> {
    var supportedTapProcessingFormat: Bool = false
    var isNonInterleaved: Bool = false
    var sampleRate: Float64 = .nan
    var audioUnit: AudioUnit?
    var sampleCount: Float64 = 0
    var leftChannelVolume: Float = 0.0
    var rightChannelVolume: Float = 0.0
    var `self`: T?
}


func AudioProcessingTapCallbacks() -> MTAudioProcessingTapCallbacks {
    return MTAudioProcessingTapCallbacks(
        version: kMTAudioProcessingTapCallbacksVersion_0,
        clientInfo: nil,
        init: initialize,
        finalize: finalize,
        prepare: prepare,
        unprepare: unprepare,
        process: process)
}

//MARK: - callbacks
private func initialize(
    tap: MTAudioProcessingTap,
    info: UnsafeMutableRawPointer?,
    storageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) {
    storageOut.pointee = bridge(to: AVAudioTapProcessorContext<Player>())
}


private func finalize(tap: MTAudioProcessingTap) {
    Unmanaged<AVAudioTapProcessorContext<Player>>.fromOpaque(UnsafeRawPointer(MTAudioProcessingTapGetStorage(tap))).release()
}


private func prepare(
    tap: MTAudioProcessingTap,
    maxFrames: CMItemCount,
    processingFormatPointer: UnsafePointer<AudioStreamBasicDescription>
) {
    let processingFormat = processingFormatPointer.pointee

    let context = bridgeUnretained(from: MTAudioProcessingTapGetStorage(tap)) as AVAudioTapProcessorContext<Player>
    context.supportedTapProcessingFormat = true
    context.sampleRate = processingFormat.mSampleRate
    if processingFormat.mFormatID != kAudioFormatLinearPCM {
        context.supportedTapProcessingFormat = false
    }

    if processingFormat.mFormatFlags & kAudioFormatFlagIsFloat == 0 {
        context.supportedTapProcessingFormat = false
    }

    if processingFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved == 1 {
        context.isNonInterleaved = true
    }

    var audioUnit: AudioUnit? {
        var desc = AudioComponentDescription()
        desc.componentType = kAudioUnitType_Effect
        desc.componentSubType = kAudioUnitSubType_BandPassFilter
        desc.componentManufacturer = kAudioUnitManufacturer_Apple
        desc.componentFlags = 0
        desc.componentFlagsMask = 0

        guard let component = AudioComponentFindNext(nil, &desc) else { return nil }

        var _unit: AudioUnit?
        guard AudioComponentInstanceNew(component, &_unit) == noErr, let unit = _unit  else { return nil }
        defer {
            if status == noErr {
                status = AudioUnitInitialize(unit)
            }
            if status != noErr {
                AudioComponentInstanceDispose(unit)
            }
        }

        func sizeof<T>(_ type: T.Type) -> UInt32 {
            return UInt32(MemoryLayout<T>.size)
        }
        var status: OSStatus
        status = AudioUnitSetProperty(
            unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0,
            processingFormatPointer, sizeof(AudioStreamBasicDescription.self))
        guard status == noErr else { return nil }

        status = AudioUnitSetProperty(
            unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0,
            processingFormatPointer, sizeof(AudioStreamBasicDescription.self))
        guard status == noErr else { return nil }

        var callback = AURenderCallbackStruct()
        callback.inputProc = auRenderCallback
        callback.inputProcRefCon = bridgeUnretained(to: tap)

        status = AudioUnitSetProperty(
            unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input,
            0, &callback, sizeof(AURenderCallbackStruct.self))
        guard status == noErr else { return nil }

        var maximumFramesPerSlice = UInt32(maxFrames)
        status = AudioUnitSetProperty(
            unit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global,
            0, &maximumFramesPerSlice, sizeof(UInt32.self))
        guard status == noErr else { return nil }

        return unit
    }

    context.audioUnit = audioUnit
}


private func unprepare(tap: MTAudioProcessingTap) {
    let context = bridgeUnretained(from: MTAudioProcessingTapGetStorage(tap)) as AVAudioTapProcessorContext<Player>
    if let unit = context.audioUnit {
        AudioUnitUninitialize(unit)
        AudioComponentInstanceDispose(unit)
        context.audioUnit = nil
    }
}


//swiftlint:disable function_parameter_count
private func process(
    tap: MTAudioProcessingTap,
    numberFrames: CMItemCount,
    flags: MTAudioProcessingTapFlags,
    bufferListInOut: UnsafeMutablePointer<AudioBufferList>,
    numberFramesOut: UnsafeMutablePointer<CMItemCount>,
    flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>
) {
    let context = bridgeUnretained(from: MTAudioProcessingTapGetStorage(tap)) as AVAudioTapProcessorContext<Player>
    var status: OSStatus = noErr
    defer {
        if status != noErr {
            MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
        }
    }
    if let audioUnit = context.audioUnit {
        var timeStamp = AudioTimeStamp()
        timeStamp.mSampleTime = context.sampleCount
        timeStamp.mFlags = .sampleTimeValid

        status = AudioUnitRender(
            audioUnit, nil, &timeStamp, 0, UInt32(numberFrames), bufferListInOut)
        guard status == noErr else { return }

        context.sampleCount += Float64(numberFrames)
        numberFramesOut.pointee = numberFrames
    }
}

//MARK: - AURenderCallback
private func auRenderCallback(
    inRefCon: UnsafeMutableRawPointer,
    ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp: UnsafePointer<AudioTimeStamp>,
    inBusNumber: UInt32,
    inNumberFrames: UInt32,
    ioData: UnsafeMutablePointer<AudioBufferList>?
) -> OSStatus {
    return MTAudioProcessingTapGetSourceAudio(bridgeUnretained(from: inRefCon), CMItemCount(inNumberFrames), ioData!, nil, nil, nil)
}

//MARK: - helper

private func bridge<T: AnyObject>(to obj: T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passRetained(obj).toOpaque())
}

private func bridgeUnretained<T: AnyObject>(from pointer: UnsafeMutableRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue()
}

private func bridgeUnretained<T: AnyObject>(to obj: T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}
