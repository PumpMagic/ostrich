//
//  BIT.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/17/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Test a given bit of an operand
struct BIT
    <T: Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == UInt8
{
    let op: T
    let bit: UInt8
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: Z80) {
        modifyFlags(cpu, num: op.read())
    }
    
    func runOn(_ cpu: LR35902) {
        modifyFlags(cpu, num: op.read())
    }
    
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, num: T.ReadType) {
        // Z is set if specified bit is 0; otherwise, it is reset.
        // H is set.
        // N is reset.
        // C is not affected.
        
        cpu.ZF.write(!bitIsHigh(num, bit: bit))
        cpu.HF.write(true)
        cpu.NF.write(false)
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, num: T.ReadType) {
        modifyCommonFlags(cpu, num: num)
        
        // S is unknown.
        // P/V is unknown.
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, num: T.ReadType) {
        modifyCommonFlags(cpu, num: num)
    }
}
