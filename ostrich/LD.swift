//
//  LD.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Load: store an operand in another operand.
struct LD
    <T: protocol<Writeable, OperandType>,
    U: protocol<Readable, OperandType>
    where T.WriteType == U.ReadType>: Instruction
{
    let dest: T
    let src: U
    
    var cycleCount: Int {
        get {
            //@todo switch, accurate values
            if dest.operandType == .Register8Like && src.operandType == .Register8Like { return 1 }
            if dest.operandType == .Register8Like && src.operandType == .Memory8Like { return 1 }
            if dest.operandType == .Memory8Like && src.operandType == .Register8Like { return 1 }
            if dest.operandType == .Memory8Like && src.operandType == .Memory8Like { return 1 }
            
            return 0
        }
    }
    
    func runOn(z80: Z80) {
        print("Running LD")
        
        dest.write(src.read())
        
        // No LD modifies flags.
    }
}