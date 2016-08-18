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


class Counter<T: IntegerType> {
    private var value: T
    
    let maxValue: T
    var onFire: (Void -> Void)?
    var isFired: Bool { return self.value == 0 }
    var enabled: Bool
    
    
    func load(newValue: T) {
        if newValue > self.maxValue {
            print("FATAL: load of invalid value")
            exit(1)
        }
        
        self.value = newValue
    }
    
    func clock() {
        if self.enabled {
            if self.value > 0 {
                let newValue = self.value - 1
                self.value = newValue
                if newValue == 0 {
                    if let onFire = self.onFire {
                        onFire()
                    }
                }
            }
        }
    }
    
    func resetIfFired() {
        if self.value == 0 {
            self.load(self.maxValue)
        }
    }
    
    init(value: T, maxValue: T, onFire: (Void -> Void)?) {
        self.value = value
        self.maxValue = maxValue
        self.onFire = onFire
        self.enabled = true
    }
}