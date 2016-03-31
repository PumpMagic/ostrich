//
//  RST.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/30/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Restart: push PC onto the stack, then set PC to a constant
struct RST: Instruction {
    // (SP – 1) ← PCH, (SP – 2) ← PCL, PCH ← 0, PCL ← P
    //@todo consider validating the constant: valid values are 0x00, 0x08, 0x10, 0x18 ... 0x38
    
    let cycleCount = 0
    
    let restartAddress: Address
    
    func runOn(z80: Z80) {
        let currentPC = z80.PC.read()
        let currentSP = z80.SP.read()
        
        print(String(format: "Running RST. SP before: 0x%04X", currentSP))
        print(String(format: "\tPC before: 0x%04X", currentPC))
        
        Memory16Translator(addr: currentSP-2, memory: z80.memory).write(currentPC)
        z80.SP.write(currentSP - 2)
        
        z80.PC.write(restartAddress)
        
        print(String(format: "\tSP after: 0x%04X", z80.SP.read()))
        print(String(format: "\tPC after: 0x%04X", z80.PC.read()))
    }
}