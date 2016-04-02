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
        print("Before RST: \n\(z80.pcsp)")
        
        z80.push(z80.PC.read())
        z80.PC.write(restartAddress)
        
        print("After RST: \n\(z80.pcsp)")
    }
}