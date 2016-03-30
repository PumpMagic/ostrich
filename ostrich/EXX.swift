//
//  EXX.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Three-way exchange: exchange three specific pairs of registers
struct EXX: Instruction {
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("Running EXX")
        
        let bcValue = z80.BC.read()
        let bcpValue = z80.BCp.read()
        let deValue = z80.DE.read()
        let depValue = z80.DEp.read()
        let hlValue = z80.HL.read()
        let hlpValue = z80.HLp.read()
        
        z80.BC.write(bcpValue)
        z80.BCp.write(bcValue)
        z80.DE.write(depValue)
        z80.DEp.write(deValue)
        z80.HL.write(hlpValue)
        z80.HLp.write(hlValue)
        
        // EXX does not modify flags.
    }
}