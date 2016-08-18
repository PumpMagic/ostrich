//
//  GBSPlayer.swift
//  audiotest
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


func getByte(data: NSData, addr: Int) -> UInt8 {
    var readByte: UInt8 = 0
    data.getBytes(&readByte, range: NSMakeRange(addr, 1))
    return readByte
}

//@todo duplicated w/ ostrich
func make16(high high: UInt8, low: UInt8) -> UInt16 {
    var result = UInt16(high)
    result <<= 8
    result |= UInt16(low)
    
    return result
}

//@todo duplicated w/ ostrich
/// Reads two bytes of memory and returns them in host endianness
func getDByte(data: NSData, addr: Int) -> UInt16 {
    let low = getByte(data, addr: addr)
    let high = getByte(data, addr: addr+1)
    
    return make16(high: high, low: low)
}

func getBytes(data: NSData, addr: Int, length: Int) -> [UInt8] {
    var readBytes: [UInt8] = [UInt8](count: length, repeatedValue: 0)
    
    data.getBytes(&readBytes, range: NSMakeRange(addr, length))
    
    return readBytes
}


/*
 Offset Size Description
 ====== ==== ==========================
 00       3  Identifier string ("GBS")
 03       1  Version (1)
 04       1  Number of songs (1-255)
 05       1  First song (usually 1)
 06       2  Load address ($400-$7fff)
 08       2  Init address ($400-$7fff)
 0a       2  Play address ($400-$7fff)
 0c       2  Stack pointer
 0e       1  Timer modulo  (see TIMING)
 0f       1  Timer control (see TIMING)
 10      32  Title string
 30      32  Author string
 50      32  Copyright string
 70   nnnn Code and Data (see RST VECTORS)
 */
let GBS_ID_OFFSET = 0x00
let GBS_ID_LENGTH = 0x03
let GBS_VERSION_OFFSET = 0x03
let GBS_NUM_SONGS_OFFSET = 0x04
let GBS_FIRST_SONG_OFFSET = 0x05
let GBS_LOAD_ADDRESS_OFFSET = 0x06
let GBS_INIT_ADDRESS_OFFSET = 0x08
let GBS_PLAY_ADDRESS_OFFSET = 0x0a
let GBS_STACK_POINTER_OFFSET = 0x0c
let GBS_TIMER_MODULO_OFFSET = 0x0e
let GBS_TIMER_CONTROL_OFFSET = 0x0f
let GBS_TITLE_OFFSET = 0x10
let GBS_TITLE_LENGTH = 0x20
let GBS_AUTHOR_OFFSET = 0x30
let GBS_AUTHOR_LENGTH = 0x20
let GBS_COPYRIGHT_OFFSET = 0x50
let GBS_COPYRIGHT_LENGTH = 0x20
let GBS_CODE_AND_DATA_OFFSET = 0x70

struct GBSHeader: CustomStringConvertible {
    let id: String
    let version: UInt8
    let numSongs: UInt8
    let firstSong: UInt8
    let loadAddress: UInt16
    let initAddress: UInt16
    let playAddress: UInt16
    let stackPointer: UInt16
    let timerModulo: UInt8
    let timerControl: UInt8
    let title: String
    let author: String
    let copyright: String
    
    var description: String {
        get {
            var str = "GBS header"
            str += "\n\tid: \(id)"
            str += String(format: "\n\tversion: 0x%02X", version)
            str += String(format: "\n\tnumSongs: 0x%02X", numSongs)
            str += String(format: "\n\tfirstSong: 0x%02X", firstSong)
            str += String(format: "\n\tloadAddress: 0x%04X", loadAddress)
            str += String(format: "\n\tinitAddress: 0x%04X", initAddress)
            str += String(format: "\n\tplayAddress: 0x%04X", playAddress)
            str += String(format: "\n\tstackPointer: 0x%04X", stackPointer)
            str += String(format: "\n\ttimerModulo: 0x%02X", timerModulo)
            str += String(format: "\n\ttimerControl: 0x%02X", timerControl)
            str += "\n\ttitle: \(title)"
            str += "\n\tauthor: \(author)"
            str += "\n\tcopyright: \(copyright)"
            
            return str
        }
    }
}

func removeNuls(string: String) -> String {
    let set = NSCharacterSet(charactersInString: "\0")
    return string.stringByTrimmingCharactersInSet(set)
}

func parseFile(path: String) -> (header: GBSHeader, codeAndData: NSData)? {
    guard let rawData = NSData(contentsOfFile: path) else {
        print("Unable to find file at \(path)")
        return nil
    }
    
    guard let id = String(bytes: getBytes(rawData, addr: GBS_ID_OFFSET, length: GBS_ID_LENGTH), encoding: NSUTF8StringEncoding) else
    {
        return nil
    }
    let version = getByte(rawData, addr: GBS_VERSION_OFFSET)
    let numSongs = getByte(rawData, addr: GBS_NUM_SONGS_OFFSET)
    let firstSong = getByte(rawData, addr: GBS_FIRST_SONG_OFFSET)
    let loadAddress = getDByte(rawData, addr: GBS_LOAD_ADDRESS_OFFSET)
    let initAddress = getDByte(rawData, addr: GBS_INIT_ADDRESS_OFFSET)
    let playAddress = getDByte(rawData, addr: GBS_PLAY_ADDRESS_OFFSET)
    let stackPointer = getDByte(rawData, addr: GBS_STACK_POINTER_OFFSET)
    let timerModulo = getByte(rawData, addr: GBS_TIMER_MODULO_OFFSET)
    let timerControl = getByte(rawData, addr: GBS_TIMER_CONTROL_OFFSET)
    guard let titleRaw = String(bytes: getBytes(rawData, addr: GBS_TITLE_OFFSET, length: GBS_TITLE_LENGTH),
                       encoding: NSUTF8StringEncoding),
              authorRaw = String(bytes: getBytes(rawData, addr: GBS_AUTHOR_OFFSET, length: GBS_AUTHOR_LENGTH),
                       encoding: NSUTF8StringEncoding),
              copyrightRaw = String(bytes: getBytes(rawData, addr: GBS_COPYRIGHT_OFFSET, length: GBS_COPYRIGHT_LENGTH), encoding: NSUTF8StringEncoding) else
    {
                    return nil
    }
    
    let title = removeNuls(titleRaw)
    let author = removeNuls(authorRaw)
    let copyright = removeNuls(copyrightRaw)
    
    let header = GBSHeader(id: id, version: version, numSongs: numSongs, firstSong: firstSong, loadAddress: loadAddress, initAddress: initAddress, playAddress: playAddress, stackPointer: stackPointer, timerModulo: timerModulo, timerControl: timerControl, title: title, author: author, copyright: copyright)
    
    let codeAndData = rawData.subdataWithRange(NSMakeRange(GBS_CODE_AND_DATA_OFFSET, rawData.length-GBS_CODE_AND_DATA_OFFSET))
    
    return (header, codeAndData)
}


func playFile(path: String) {
    /*
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
    */
}