//
//  main.swift
//  ostrich
//
//  Created by Ryan Conway on 12/9/15.
//  Copyright © 2015 conwarez. All rights reserved.
//

import Foundation


let ROM_PATH: String = "/Users/ryanconway/Dropbox/emu/SML.gb"

guard let rawData = NSData(contentsOfFile: ROM_PATH) else {
    print("Unable to find rom at \(ROM_PATH)")
    exit(1)
}

print("Found rom at \(ROM_PATH)")
print("The rom is \(rawData.length) bytes long")

let myRom = Memory(data: rawData)
let myZ80 = Z80(memory: myRom)

var iteration = 1
repeat {
    guard let instruction = myZ80.getInstruction() else {
        print("Okay, bye")
        exit(1)
    }
    print("\(iteration): \(instruction)")
    instruction.runOn(myZ80)
    iteration += 1
} while true
