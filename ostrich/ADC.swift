//
//  ADC.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Add with carry
struct ADC<T: protocol<Readable, OperandType>>: Instruction {
    // A <- A + s + CY
    let operand: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("Running ADC")
        
        /*
         switch operand {
         case .Operand8Bit(let op8):
         let val = self.resolveOperand(op8)
         let original = A
         let previous_carry: UInt8 = F.C ? 1 : 0
         A = A &+ val &+ previous_carry
         
         // Set the flags
         // Sign flag: set if result is negative (copy of MSB)
         if (A & 0x80 != 0) { F.S = true } else { F.S = false }
         // Zero flag: set if result is zero
         if (A == 0) { F.Z = true } else { F.Z = false }
         // Half Carry flag: set if carry from bit 3 to 4 occurred
         if (((original & 0x0F) + (val & 0x0F) + previous_carry) >= 0x10) { F.H = true } else { F.H = false }
         // Parity/Overflow flag: set if overflow
         // really just carry xor bit 6->7 carry
         // "set when both operands are positive and signed sum is negative or both operands are negative and the signed sum is positive"
         //@todo genericize for sub: http://stackoverflow.com/questions/8034566/overflow-and-carry-flags-on-z80
         if ((Int8(original) > 0 && Int8(val) > 0 && Int8(A) < 0) ||
         (Int8(original) < 0 && Int8(val) < 0 && Int8(A) > 0))
         {
         F.PV = true
         }
         // Add/Subtract flag: reset
         F.N = false
         // Carry flag: imaginary 9th bit
         let sum_with_overflow: UInt16 = UInt16(A) + UInt16(val) + UInt16(previous_carry)
         if (sum_with_overflow > 0xFF) {
         F.C = true
         } else {
         F.C = false
         }
         case .Operand16Bit(_):
         print("Unimplemented or unsupported register combination")
         exit(1)
         }
         */
    }
}