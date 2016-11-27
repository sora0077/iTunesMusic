//
//  AudioProcessingTapCallbacks.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/11/27.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import MediaToolbox


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

//MARK: callbacks
private func initialize(
    tap: MTAudioProcessingTap,
    info: UnsafeMutableRawPointer?,
    storageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>
    ) {

}


private func finalize(tap: MTAudioProcessingTap) {

}


private func prepare(
    tap: MTAudioProcessingTap,
    maxFrames: CMItemCount,
    processingFormat: UnsafePointer<AudioStreamBasicDescription>
    ) {

}


private func unprepare(tap: MTAudioProcessingTap) {

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
    let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
    print("get audio: \(status)\n")
    print(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)
}
