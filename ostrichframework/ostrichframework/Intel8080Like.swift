//
//  8080Like.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/6/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Everything in common between the Z80 and the LR35902.
protocol Intel8080Like {
    var A: Register8 { get }
    var B: Register8 { get }
    var C: Register8 { get }
    var D: Register8 { get }
    var E: Register8 { get }
    var F: Register8 { get }
    var H: Register8 { get }
    var L: Register8 { get }
    
    var I: Register8 { get }
    var R: Register8 { get }
    
    var SP: Register16 { get }
    var PC: Register16 { get }
    
    var ZF: Flag { get }
    var NF: Flag { get }
    var HF: Flag { get }
    var CF: Flag { get }
}