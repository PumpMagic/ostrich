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
    <T: protocol<Readable, OperandType> where T.ReadType == UInt8>: Z80Instruction, LR35902Instruction
{
    let op: T
    let bit: UInt8
    
    let cycleCount = 0
    
    
    func runOn(cpu: Z80) {
        modifyFlags(cpu, num: op.read())
    }
    
    func runOn(cpu: LR35902) {
        modifyFlags(cpu, num: op.read())
    }
    
    
    private func modifyCommonFlags(cpu: Intel8080Like, num: T.ReadType) {
        // Z is set if specified bit is 0; otherwise, it is reset.
        // H is set.
        // N is reset.
        // C is not affected.
        
        cpu.ZF.write(!bitIsHigh(num, bit: bit))
        cpu.HF.write(true)
        cpu.NF.write(false)
    }
    
    private func modifyFlags(cpu: Z80, num: T.ReadType) {
        modifyCommonFlags(cpu, num: num)
        
        // S is unknown.
        // P/V is unknown.
    }
    
    private func modifyFlags(cpu: LR35902, num: T.ReadType) {
        modifyCommonFlags(cpu, num: num)
    }
}