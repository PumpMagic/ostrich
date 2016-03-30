//
//  Util.swift
//  ostrich
//
//  Created by Ryan Conway on 2/21/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


// Utility
/// Make a `UInt16` out of two individual bytes
func make16(high high: UInt8, low: UInt8) -> UInt16 {
    var result = UInt16(high)
    result <<= 8
    result |= UInt16(low)
    
    return result
}

/// Returns (MSB, LSB) of a host-endian 16-bit number
func getBytes(val: UInt16) -> (UInt8, UInt8) {
    return (getHigh(val), getLow(val))
}

/// Get the least significant byte of a host-endian 16-bit number
func getLow(val: UInt16) -> UInt8 {
    return UInt8(val)
}

/// Get the most significant byte of a host-endian 16-bit number
func getHigh(val: UInt16) -> UInt8 {
    return UInt8(val >> 8)
}

/// Determine if a number is "negative" (if its MSB is high)
func numberIsNegative(num: UInt16) -> Bool {
    return bitIsHigh(num, bit: 15)
}

/// For symmetry or something
func numberIsZero(num: UInt16) -> Bool {
    return num == 0
}

/// Test a zero-based bit of a 16-bit number
func bitIsHigh(num: UInt16, bit: UInt8) -> Bool {
    let mask = UInt16(0x0001 << bit)
    if num & mask != 0 {
        return true
    }
    
    return false
}