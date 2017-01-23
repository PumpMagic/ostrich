//
//  GBSPlayer.swift
//  gbsplayer
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation
import AudioKit
@testable import ostrich


/// Number of nanoseconds in one 256th of a second
let NS_256HZ = 3906250
/// Number of nanoseconds in one second
let NS_PER_S = 1000000000
/// An approximation of the Game Boy V-blank rate, in Hz
let VBLANK_HZ = 59.7


/// A GBS player: a Game Boy manager that loads its memory and clocks its CPU and APU according to a GBS file and user interaction
class GBSPlayer {
    var gameBoy: GameBoy
    var gbsHeader: GBSHeader? // header of most recently loaded GBS file
    
    let queue: DispatchQueue
    var apuClocker: DispatchSourceTimer
    var cpuClocker: DispatchSourceTimer
    var isPlaying: Bool
    
    
    init() {
        self.gameBoy = GameBoy()
        self.gbsHeader = nil
        
        self.queue = DispatchQueue(label: "com.rmconway.gbsplayer", qos: DispatchQoS.userInteractive)
        self.apuClocker = DispatchSource.makeTimerSource(queue: self.queue)
        self.cpuClocker = DispatchSource.makeTimerSource(queue: self.queue)
        self.isPlaying = false
    }
    
    /// Run the GBS spec's "LOAD" phase
    /// This loads the GBS file's "code and data" section into the Game Boy's ROM (loads its cart)
    /// After loading, page 0 is in bank 0, and page 1 is in bank 1.
    private func runGBSLoadPhase(codeAndData: Data) {
        guard let header = self.gbsHeader else {
            print("No GBS header present")
            return
        }
        
        self.gameBoy.insertCartridge(rom: codeAndData, romStartAddress: header.loadAddress)
    }
    
    /// Run the GBS spec's "INIT" phase
    /// This initializes all of the Game Boy's registers, clears its RAM, loads the desired song number into its CPU's accumulator,
    /// and has its CPU run a CALL with the GBS header's init address
    private func runGBSInitPhase(track: UInt8) {
        guard let header = self.gbsHeader else {
            print("No GBS header present")
            return
        }
        
        gameBoy.cpu.resetRegisters()
        gameBoy.cpu.setSP(header.stackPointer)
        gameBoy.cpu.setPC(header.loadAddress)
        gameBoy.cpu.setA(track)
        gameBoy.cpu.call(header.initAddress)
    }
    
    /// Calculate the audio routine call rate according to the GBS spec and the current header file
    private func calculateAudioRoutineCallRate() -> Double {
        guard let header = self.gbsHeader else {
            print("No GBS header present")
            return 0.0
        }
        
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
            audioRoutineCallRate = 1 / VBLANK_HZ
        }
        
        print("Audio routine call rate is \(1/audioRoutineCallRate)Hz")
        
        return audioRoutineCallRate
    }
    
    
    /// Run the GBS spec's "PLAY" phase
    /// This constantly has the Game Boy's CPU CALL the GBS header's PLAY address at a rate according to its timer control fields
    /// (We also start clocking the Game Boy's APU here, @todo make that internal to the Game Boy class)
    private func runGBSPlayPhase() {
        guard let header = self.gbsHeader else {
            print("No GBS header present")
            return
        }
        
        let audioRoutineCallRate = self.calculateAudioRoutineCallRate()
        
        // At 256Hz, clock the APU's 256Hz clock
        apuClocker.scheduleRepeating(deadline: .now(), interval: .nanoseconds(NS_256HZ), leeway: .nanoseconds(10))
        apuClocker.setEventHandler() {
            self.gameBoy.apu.clock256()
        }
        
        // At whatever the audio call rate is, run the audio routine on the CPU
        let audioRoutineCallRateNS = Int(audioRoutineCallRate * NS_PER_S)
        cpuClocker.scheduleRepeating(deadline: .now(), interval: .nanoseconds(audioRoutineCallRateNS), leeway: .nanoseconds(10))
        cpuClocker.setEventHandler() {
            self.gameBoy.cpu.call(header.playAddress)
        }
        
        /// Start the timers
        self.apuClocker.resume()
        self.cpuClocker.resume()
    }
    
    
    /// Load a GBS file
    func loadGBSFile(path: String) {
        guard let (header, codeAndData) = parseGBSFile(GBS_PATH) else {
            exit(1)
        }
        
        print("\(header)\n")
        
        self.gbsHeader = header
        
        self.runGBSLoadPhase(codeAndData: codeAndData)
        self.runGBSInitPhase(track: header.firstSong)
//        self.runGBSPlayPhase()
    }
    
    /// Load a track
    func playTrack(track: UInt8) {
        self.runGBSInitPhase(track: track)
        self.stopPlaying()
        self.runGBSPlayPhase()
        self.isPlaying = true
    }
    
    /// Set the volume. Range: [0.0, 1.0]
    func setVolume(level: Double) {
        self.gameBoy.setVolume(level: level)
    }
    
    func stopPlaying() {
        self.gameBoy.setVolume(level: 0.0)
        
        if self.isPlaying {
            self.apuClocker.suspend()
            self.cpuClocker.suspend()
            
            sleep(1)
            
            self.isPlaying = false
        }
    }
}
