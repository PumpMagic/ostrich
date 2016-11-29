//
//  Channel.swift
//  audiotest
//
//  Created by Ryan Conway on 5/1/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Has a length counter that automatically disables a channel when the counter is enabled and decrements to zero
protocol HasLengthCounter {
    var lengthCounterLoad: UInt8 { set get }
    var lengthEnable: UInt8 { set get }
    
    func clock256()
}


/// Has a volume envelope that can automatically sweep volume
protocol HasVolumeEnvelope {
    var startingVolume: UInt8 { set get }
    var envelopeAddMode: UInt8 { set get }
    var envelopePeriod: UInt8 { set get }
    
    func clock64()
}
