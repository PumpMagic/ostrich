//
//  main.swift
//  ostrich
//
//  Created by Ryan Conway on 12/9/15.
//  Copyright © 2015 conwarez. All rights reserved.
//

import Foundation

let ROM_PATH: String = "/Users/ryanconway/Dropbox/emu/SML.gb"

class gbRom {
    let data: NSData
    
    init (_ data: NSData) {
        self.data = data
    }
    
    func getByte (addr: UInt16) -> UInt8? {
        var readByte: UInt8 = 0
        data.getBytes(&readByte, length: 1)
        data.getBytes(&readByte, range: NSMakeRange(Int(addr), 1))
        return readByte
    }
}

class z80 {
    // 8-bit registers
    var A: UInt8
    var B: UInt8
    var C: UInt8
    var D: UInt8
    var E: UInt8
    var F: UInt8 // flag
    var H: UInt8
    var L: UInt8
    var SP: UInt16
    var PC: UInt16
    
    // 16-bit registers - just combinations of some of the 8-bit registers
    var AF: UInt16 {
        get {
            var result = UInt16(A)
            result <<= 8
            result |= UInt16(F)
            return result
        }
        set {
            A = UInt8(newValue >> 8)
            F = UInt8(newValue)
        }
    }
    var BC: UInt16 {
        get {
            var result = UInt16(B)
            result <<= 8
            result |= UInt16(C)
            return result
        }
        set {
            B = UInt8(newValue >> 8)
            C = UInt8(newValue)
        }
    }
    var DE: UInt16 {
        get {
            var result = UInt16(D)
            result <<= 8
            result |= UInt16(E)
            return result
        }
        set {
            D = UInt8(newValue >> 8)
            E = UInt8(newValue)
        }
    }
    var HL: UInt16 {
        get {
            var result = UInt16(H)
            result <<= 8
            result |= UInt16(L)
            return result
        }
        set {
            H = UInt8(newValue >> 8)
            L = UInt8(newValue)
        }
    }
    /*@todo
    var flags: Flags {
        get {
            
        }
    }
    */
    
    init() {
        A = 0
        B = 0
        C = 0
        D = 0
        E = 0
        F = 0
        H = 0
        L = 0
        SP = 0
        PC = 0x100
    }
    
    /*  LD r, r'
    
    */
    
    /*
        to read instruction:
            1. examine first byte.
                is it CB, DD, ED, or FD? read next byte; opcode is these two bytes.
                is it anything else? opcode is that byte.
            2. examine opcode.
                7F: LD A,A
                78: LD A,B
    */
    
    enum Instruction {
        case NOP // do nothing
        case JP(UInt16) // jump to nn (sets PC for next instruction)
    }
    
    func getInstruction(rom: gbRom) -> Instruction? {
        print("Loading instruction. PC is \(PC)")
        
        let firstByte = rom.getByte(PC)!
        
        switch firstByte {
            case 0x00:
                PC += 1
                return Instruction.NOP
            case 0xC3:
                let addrHigh = rom.getByte(PC+1)!
                let addrLow = rom.getByte(PC+2)!
                let addr: UInt16 = (UInt16(addrHigh) << 8) | (UInt16(addrLow))
                PC += 3
                return Instruction.JP(addr)
            default:
                return nil
        }
    }
}




guard let rawData = NSData(contentsOfFile: ROM_PATH) else {
    print("Unable to find rom at \(ROM_PATH)")
    exit(-1)
}

print("Found rom at \(ROM_PATH)")
print("The rom is \(rawData.length) bytes long")

let myZ80 = z80()
let myRom = gbRom(rawData)

print("1: \(myZ80.getInstruction(myRom))")
print("2: \(myZ80.getInstruction(myRom))")
print("3: \(myZ80.getInstruction(myRom))")