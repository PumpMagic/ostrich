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

func toImplAmplitude(volume: UInt8) -> Double {
    if volume <= Pulse.MAX_VOLUME {
        return Double(volume) / Double(Pulse.MAX_VOLUME)
    }
    
    return 1.0
}

func toImplFrequency(frequency: UInt16) -> Double {
    if frequency == 0 {
        return 0
    }
    
    //@todo this is channel type-specific
    return (GB_CLOCK_HZ / SAMPLES_PER_PULSE_WAVE_PERIOD) / Double((2048-frequency)) / 4
}