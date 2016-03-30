//
//  Util.swift
//  audiotest
//
//  Created by Ryan Conway on 3/26/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


let GB_CLOCK_HZ = 4194304.0
let SAMPLES_PER_PULSE_WAVE_PERIOD = 8.0
let MAX_VOLUME_REGISTER_VALUE: UInt = 15

func toImplAmplitude(volume: UInt) -> Double {
    if volume <= MAX_VOLUME_REGISTER_VALUE {
        return Double(volume) / Double(MAX_VOLUME_REGISTER_VALUE)
    }
    
    return 1.0
}

func toImplFrequency(frequency: UInt) -> Double {
    return GB_CLOCK_HZ / SAMPLES_PER_PULSE_WAVE_PERIOD / Double(frequency)
}