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
    return UInt8(truncatingBitPattern: val)
}

/// Get the most significant byte of a host-endian 16-bit number
func getHigh(val: UInt16) -> UInt8 {
    return UInt8(val >> 8)
}

/// Determine if a number is "negative" (if its MSB is high)
func numberIsNegative(num: UInt16) -> Bool {
    return bitIsHigh(num, bit: 15)
}

func numberIsNegative(num: UInt8) -> Bool {
    return bitIsHigh(num, bit: 7)
}

/// For symmetry or something
func numberIsZero(num: UInt16) -> Bool {
    return num == 0
}

func numberIsZero(num: UInt8) -> Bool {
    return num == 0
}

/// Test a zero-based bit of a 16-bit number
public func bitIsHigh(num: UInt16, bit: UInt8) -> Bool {
    let mask = UInt16(0x0001 << bit)
    if num & mask != 0 {
        return true
    }
    
    return false
}

/// Test a zero-based bit of an 8-bit number
public func bitIsHigh(num: UInt8, bit: UInt8) -> Bool {
    let mask = UInt8(0x01 << bit)
    if num & mask != 0 {
        return true
    }
    
    return false
}

func setBit(num: UInt8, bit: UInt8) -> UInt8 {
    let mask = UInt8(0x01 << bit)
    
    return num | mask
}

func clearBit(num: UInt8, bit: UInt8) -> UInt8 {
    let mask = ~(UInt8(0x01 << bit))
    
    return num & mask
}

/// Perform a right rotate in a way that doesn't depend on Swift's sign-specific shifting behavior
func rotateRight(num: UInt8) -> UInt8 {
    // Shift the number
    let shifted = num >> 1
    
    // Loop the number's least-significant bit back to the most-significant bit
    let newValue: UInt8
    if bitIsHigh(num, bit: 0) {
        newValue = setBit(shifted, bit: 7)
    } else {
        newValue = clearBit(shifted, bit: 7)
    }
    
    return newValue
}

/// Perform a left rotate in a way that doesn't depend on Swift's sign-specific shifting behavior
func rotateLeft(num: UInt8) -> UInt8 {
    // Shift the number
    let shifted = num << 1
    
    // Loop the number's most-significant bit back to the most-significant bit
    let newValue: UInt8
    if bitIsHigh(num, bit: 7) {
        newValue = setBit(shifted, bit: 0)
    } else {
        newValue = clearBit(shifted, bit: 0)
    }
    
    return newValue
}

// ADD STUFF
func addOverflowOccurred(op1: UInt8, _ op2: UInt8, result: UInt8) -> Bool {
    if numberIsNegative(op1) && numberIsNegative(op2) && !numberIsNegative(result) {
        return true
    }
    if !numberIsNegative(op1) && !numberIsNegative(op2) && numberIsNegative(result) {
        return true
    }
    
    return false
}

func addHalfCarryProne(op1: UInt8, _ op2: UInt8) -> Bool {
    return (op1 & 0x0F) + (op2 & 0x0F) >= 0x10
}

/// Z80 half-carry for 16-bit numbers is on bit 11, not bit 7
func addHalfCarryProne(op1: UInt16, _ op2: UInt16) -> Bool {
    return (op1 & 0x07FF) + (op2 & 0x07FF) >= 0x0800
}

func addHalfCarryProne(op1: UInt16, _ op2: Int8) -> Bool {
    return Int(op1 & 0x07FF) + Int(op2) >= 0x0800
}

func addCarryProne(op1: UInt8, _ op2: UInt8) -> Bool {
    let overflowedResult: UInt16 = UInt16(op1) + UInt16(op2)
    
    return overflowedResult > 0xFF
}

func addCarryProne(op1: UInt16, _ op2: UInt16) -> Bool {
    let overflowedResult: UInt32 = UInt32(op1) + UInt32(op2)
    
    return overflowedResult > 0xFFFF
}

func addCarryProne(op1: UInt16, _ op2: Int8) -> Bool {
    let overflowedResult = Int(op1) + Int(op2)
    
    return overflowedResult > 0xFFFF
}


/// Odd number of high bits: false; even number of high bits: true
func parity(num: UInt8) -> Bool {
    var highBits = 0
    
    for i in 0...7 as Range<UInt8> {
        if bitIsHigh(num, bit: i) {
            highBits = highBits + 1
        }
    }
    
    if highBits % 2 == 0 {
        return true
    }
    return false
}


protocol HexStringConvertible {
    /// Representation of this number as 0x%0#X
    var hexString: String { get }
}

extension UInt8: HexStringConvertible {
    /// Representation of this number as 0x%02X
    var hexString: String { return String(format: "0x%02X", self) }
}

extension UInt16: HexStringConvertible {
    /// Representation of this number as 0x%04X
    var hexString: String { return String(format: "0x%04X", self) }
}
