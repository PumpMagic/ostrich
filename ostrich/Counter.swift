//
//  Counter.swift
//  ostrich
//
//  Created by Ryan Conway on 8/19/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// A counter that stores a variable-width integer and automatically decrements when clocked (if nonzero).
/// Optionally calls a function when triggered.
class Counter<T: Integer> {
    fileprivate var value: T
    
    let maxValue: T
    var onFire: (() -> Void)?
    var isFired: Bool { return self.value == 0 }
    
    
    func load(_ newValue: T) {
        if newValue > self.maxValue {
            print("FATAL: load of invalid value")
            exit(1)
        }
        
        self.value = newValue
    }
    
    func clock() {
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
    
    func resetIfFired() {
        if self.value == 0 {
            self.load(self.maxValue)
        }
    }
    
    init(value: T, maxValue: T, onFire: (() -> Void)?) {
        self.value = value
        self.maxValue = maxValue
        self.onFire = onFire
    }
}
