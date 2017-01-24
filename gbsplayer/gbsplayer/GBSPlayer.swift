//
//  GBSPlayer.swift
//  gbsplayer
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation
import AudioKit
import ostrich


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
    var fileLoaded: Bool // whether or not we've been loaded with a GBS file
    var firstTrack: Int! {
        guard let header = gbsHeader else {
            return nil
        }
        
        return Int(header.firstSong)
    }
    
    let queue: DispatchQueue
    var apuClocker: DispatchSourceTimer?
    var cpuClocker: DispatchSourceTimer?
    var midSong: Bool // whether or not we've started playing a song
    var paused: Bool // whether or not playback is paused
    
    /// Audio volume. Range: [0.0, 1.0]
    var volume: Double
    
    
    init() {
        gameBoy = GameBoy()
        gbsHeader = nil
        fileLoaded = false
        
        queue = DispatchQueue(label: "com.rmconway.gbsplayer", qos: DispatchQoS.userInteractive)
        apuClocker = nil
        cpuClocker = nil
        midSong = false
        paused = false
        
        volume = 1.0
        
        muteInternally()
    }
    
    /// Run the GBS spec's "LOAD" phase
    /// This loads the GBS file's "code and data" section into the Game Boy's ROM (loads its cart)
    /// After loading, page 0 is in bank 0, and page 1 is in bank 1.
    private func runGBSLoadPhase(codeAndData: Data) {
        guard let header = self.gbsHeader else {
            return
        }
        
        gameBoy.removeCartridge()
        gameBoy.insertCartridge(rom: codeAndData, romStartAddress: header.loadAddress)
    }
    
    /// Return the accumulator value required to INIT the Game Boy to play a given track, taking
    /// the currently-loaded GBS into account.
    private func accumulatorValueFor(trackNumber: Int) -> UInt8? {
        guard let header = self.gbsHeader else {
            return nil
        }
        
        // The GBS ASM expects a zero-based track number in the accumulator
        let accumulatorValue = trackNumber-1
        if accumulatorValue < Int(UInt8.min) || accumulatorValue > Int(UInt8.max) {
            return nil
        }
        
        if trackNumber > Int(header.numSongs) {
            return nil
        }
        
        return UInt8(trackNumber-1)
    }
    
    /// Run the GBS spec's "INIT" phase
    /// This initializes all of the Game Boy's registers, clears its RAM, loads the appropriate song number into its CPU's accumulator,
    /// and has its CPU run a CALL with the GBS header's init address.
    /// This function takes in a one-based track number and
    /// returns whether or not the initialization could complete
    private func runGBSInitPhase(track: Int) -> Bool {
        guard let header = self.gbsHeader else {
            return false
        }
        
        guard let accumulatorValue = accumulatorValueFor(trackNumber: track) else {
            return false
        }
        
        gameBoy.cpu.resetRegisters()
        gameBoy.clearWriteableMemory()
        gameBoy.cpu.setSP(header.stackPointer)
        gameBoy.cpu.setPC(header.loadAddress)
        gameBoy.cpu.setA(UInt8(accumulatorValue))
        gameBoy.cpu.call(header.initAddress)
        
        return true
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
        
        return audioRoutineCallRate
    }
    
    
    /// Run the GBS spec's "PLAY" phase
    /// This constantly makes the Game Boy's CPU CALL the GBS header's PLAY address at a rate according to its timer control fields
    /// (We also start clocking the Game Boy's APU here, @todo make that internal to the Game Boy class)
    /// This returns whether or not the play phase was started
    private func runGBSPlayPhase() -> Bool {
        guard let header = self.gbsHeader else {
            return false
        }
        
        let audioRoutineCallRate = self.calculateAudioRoutineCallRate()
        
        let newAPUClocker = DispatchSource.makeTimerSource(queue: self.queue)
        let newCPUClocker = DispatchSource.makeTimerSource(queue: self.queue)
        
        apuClocker = newAPUClocker
        cpuClocker = newCPUClocker
        
        // At 256Hz, clock the APU's 256Hz clock
        newAPUClocker.scheduleRepeating(deadline: .now(), interval: .nanoseconds(NS_256HZ), leeway: .nanoseconds(10))
        newAPUClocker.setEventHandler() {
            self.gameBoy.apu.clock256()
        }
        
        // At whatever the audio call rate is, run the audio routine on the CPU
        let audioRoutineCallRateNS = Int(audioRoutineCallRate * NS_PER_S)
        newCPUClocker.scheduleRepeating(deadline: .now(), interval: .nanoseconds(audioRoutineCallRateNS), leeway: .nanoseconds(10))
        newCPUClocker.setEventHandler() {
            self.gameBoy.cpu.call(header.playAddress)
        }
        
        /// Start the timers and turn on the APU volume
        newAPUClocker.resume()
        newCPUClocker.resume()
        
        return true
    }
    
    
    /// Load a GBS file; return success or failure
    func loadGBSFile(at path: URL) -> Bool{
        guard let (header, codeAndData) = parseGBSFile(at: path) else {
            return false
        }
        
        stopPlayback()
        gbsHeader = header
        runGBSLoadPhase(codeAndData: codeAndData)
        fileLoaded = true
        
        return true
    }
    
    /// Play a track, stopping existing playback if any
    /// This function takes a one-based track value and
    /// returns whether or not playback was started successfully
    func startPlayback(of track: Int) -> Bool {
        stopPlayback()
        
        if !runGBSInitPhase(track: track) { return false }
        if !runGBSPlayPhase() { return false }
        restoreVolume()
        midSong = true
        
        return true
    }
    
    /// Pause playback
    /// (Stop clocking the Game Boy, but hold on to the clockers)
    func pausePlayback() {
        if !paused && midSong {
            guard let apuClocker = self.apuClocker, let cpuClocker = self.cpuClocker else {
                return
            }
            
            apuClocker.suspend()
            cpuClocker.suspend()
            muteInternally()
            paused = true
        }
    }
    
    /// Resume playback
    /// (Start the clockers again)
    func resumePlayback() {
        if paused && midSong {
            guard let apuClocker = self.apuClocker, let cpuClocker = self.cpuClocker else {
                return
            }
            
            apuClocker.resume()
            cpuClocker.resume()
            restoreVolume()
            paused = false
        }
    }
    
    /// Stop playback
    /// (Stop clocking the Game Boy, destroying the clocker in the process)
    func stopPlayback() {
        muteInternally()
        
        if midSong {
            // Setting the clockers to nil removes all references to the dispatch sources.
            // Doing so causes them to be released (effectively canceled) by Dispatch library magic.
            // (Apple's Swift Dispatch releases the dispatch source on ARC free.)
            // Note that in order for a dispatch source to be released, its suspend count must be zero.
            // That is: you can't release a dispatch source unless it's active!!
            if paused {
                resumePlayback()
                muteInternally()
            }
            apuClocker = nil
            cpuClocker = nil
            
            usleep(300000) // Let the clocker's existing events fire
            
            midSong = false
        }
    }
    
    func muteInternally() {
        gameBoy.setVolume(level: 0.0)
    }
    
    func restoreVolume() {
        gameBoy.setVolume(level: volume)
    }
}
