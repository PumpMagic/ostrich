//
//  EXX.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Three-way exchange: exchange three specific pairs of registers
struct EXX: Z80Instruction {
    let cycleCount = 0
    
    func runOn(_ cpu: Z80) {
        let bcValue = cpu.BC.read()
        let bcpValue = cpu.BCp.read()
        let deValue = cpu.DE.read()
        let depValue = cpu.DEp.read()
        let hlValue = cpu.HL.read()
        let hlpValue = cpu.HLp.read()
        
        cpu.BC.write(bcpValue)
        cpu.BCp.write(bcValue)
        cpu.DE.write(depValue)
        cpu.DEp.write(deValue)
        cpu.HL.write(hlpValue)
        cpu.HLp.write(hlValue)
        
        // EXX does not modify flags.
    }
}
