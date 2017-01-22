//
//  GBSPlayer.swift
//  audiotest
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation
import AudioKit
@testable import ostrich


/// A GBS player: a Game Boy manager that loads its memory and clocks its CPU and APU according to a GBS file
class GBSPlayer {
    var gameBoy: GameBoy
    var gbsHeader: GBSHeader?
    //@todo we may need to store the most recently loaded GBS' header for later
    
    let queue: DispatchQueue
    let apuClocker: DispatchSourceTimer
    let cpuClocker: DispatchSourceTimer
    
    
    init() {
        self.gameBoy = GameBoy()
        self.gbsHeader = nil
        
        self.queue = DispatchQueue(label: "com.rmconway.gbsplayer", qos: DispatchQoS.userInteractive)
        self.apuClocker = DispatchSource.makeTimerSource(queue: self.queue)
        self.cpuClocker = DispatchSource.makeTimerSource(queue: self.queue)
    }
    
    convenience init(path: String) {
        self.init()
        self.loadGBSFile(path: path)
        self.startClocking()
    }
    
    func startClocking() {
        self.apuClocker.resume()
        self.cpuClocker.resume()
    }
    
    func stopClocking() {
        self.apuClocker.suspend()
        self.cpuClocker.suspend()
    }
    
    func loadGBSFile(path: String) {
        guard let (header, codeAndData) = parseGBSFile(GBS_PATH) else {
            exit(1)
        }
        
        self.gbsHeader = header
        self.gameBoy.insertCartridge(rom: codeAndData, romStartAddress: header.loadAddress)
        
        print("\(self.gbsHeader)\n")
        
        /* LOAD - The ripped code and data is read into the player program's address space
         starting at the load address and proceeding until end-of-file or address $7fff
         is reached. After loading, Page 0 is in Bank 0 (which never changes), and Page
         1 is in Bank 1 (which can be changed during init or play). Finally, the INIT
         is called with the first song defined in the header. */
        print("Instantiating LR35902 and peripherals and executing LOAD...")
        
        gameBoy.cpu.setSP(header.stackPointer)
        gameBoy.cpu.setPC(header.loadAddress)
        
        /* INIT - Called at the end of the LOAD process, or when a new song is selected.
         All of the registers are initialized, RAM is cleared, and the init address is
         called with the song number set in the accumulator. Note that the song number
         in the accumulator is zero-based (the first song is 0). The init code must end
         with a RET instruction. */
        print("Calling and running INIT...")
        self.loadTrack(number: header.firstSong)
        
        /* PLAY - Begins after INIT process is complete. The play address is constantly
         called at the rate established in the header (see TIMING). The play code must
         end with a RET instruction. */
        var audioRoutineCallRate = 1.0
        
        if bitIsHigh(header.timerControl, bit: 2) { // interrupt type
            // use timer
            // interrupt rate = counter rate / (256 - TMA)
            var clockRate = 0
            switch getValueOfBits(header.timerControl, bits: 0...1) { // counter rate
            case 0b00:
                clockRate = 4096
            case 0b01:
                clockRate = 262144
            case 0b10:
                clockRate = 65536
            case 0b11:
                clockRate = 16384
            default:
                print("FATAL: invalid timer control!")
                exit(1)
            }
            audioRoutineCallRate = Double(256 - Int(header.timerModulo)) / Double(clockRate)
        } else {
            // use v-blank, ~59.7Hz (@todo get exact period)
            audioRoutineCallRate = 0.01675
        }
        
        print("Calling and running PLAY...")
        print("Audio routine call rate is \(1/audioRoutineCallRate)Hz")
        
        
        
        // At 256Hz, clock the APU's 256Hz clock
        apuClocker.scheduleRepeating(deadline: .now(), interval: .nanoseconds(3906250), leeway: .nanoseconds(10))
        apuClocker.setEventHandler() {
            self.gameBoy.apu.clock256()
        }
        
        // At 59.7Hz, run the audio routine on the CPU
        cpuClocker.scheduleRepeating(deadline: .now(), interval: .nanoseconds(16750418), leeway: .nanoseconds(10))
        cpuClocker.setEventHandler() {
            self.gameBoy.cpu.call(header.playAddress)
        }
    }
    
    func loadTrack(number: UInt8) {
        gameBoy.cpu.setA(number)
        //@todo UNWRAP PROPERLY! DO IT
        gameBoy.cpu.call(self.gbsHeader!.initAddress)
    }
}
