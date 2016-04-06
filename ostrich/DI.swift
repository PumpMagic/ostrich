//
//  DI.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/5/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


struct DI: Instruction {
    let cycleCount: Int = 0
    
    func runOn(z80: Z80) {
        z80.IFF1 = .Disabled
        z80.IFF2 = .Disabled
    }
}