//
//  EX.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Exchange: exchange the contents of two sets of operands.
/// This is really just a set of specialized LDs.
struct EX
    <T: protocol<Readable, Writeable, OperandType>,
    U: protocol<Readable, Writeable, OperandType>
    where T.WriteType == U.ReadType,
    U.WriteType == T.ReadType,
    T.WriteType == UInt16>: Instruction
{
    // legal combinations are quite limited: DE <-> HL, AF <-> AF', (SP) <-> HL, (SP) <-> IX, (SP) <-> IY
    // really, we should somehow limit this struct's parameters to these combinations only
    // but for ease, we allow users to instantiate invalid EX commands by saying it'll work with
    // any old 16-bit operands
    
    let op1: T
    let op2: U
    
    var cycleCount: Int {
        get {
            //@todo switch, accurate values, etc
            if op1.operandType == .Register8Like && op2.operandType == .Register8Like { return 1 }
            
            return 0
        }
    }
    
    func runOn(z80: Z80) {
        print("Running EX")
        
        let tmp = op2.read()
        
        op2.write(op1.read())
        op1.write(tmp)
        
        // No EX modifies flags.
    }
}