//
//  SWAP.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/21/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


private func swap(_ num: UInt8) -> UInt8 {
    let lowerNibble = num & 0x0F
    let upperNibble = num & 0xF0
    let swapped: UInt8 = (lowerNibble << 4) | (upperNibble >> 4)
    
    return swapped
}

/// Swap the upper and lower nibbles of an 8-bit number
struct SWAP<T: Writeable & Readable & OperandType>: LR35902Instruction where T.ReadType == T.WriteType, T.ReadType == UInt8
{
    let op: T
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: LR35902) {
        let oldValue = op.read()
        let newValue = swap(oldValue)
        
        op.write(newValue)
        
        modifyFlags(cpu, newValue: newValue)
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, newValue: UInt8) {
        // Z - Set if result is zero.
        // N - Reset.
        // H - Reset.
        // C - Reset.
        cpu.ZF.write(newValue == 0)
        cpu.NF.write(false)
        cpu.HF.write(false)
        cpu.CF.write(false)
    }
}
