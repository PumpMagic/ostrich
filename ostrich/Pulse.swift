//
//  Pulse
//  audiotest
//
//  Created by Ryan Conway on 3/21/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation
import AudioKit

/*
Square 1
NR10 FF10 -PPP NSSS Sweep period, negate, shift
NR11 FF11 DDLL LLLL Duty, Length load (64-L)
NR12 FF12 VVVV APPP Starting volume, Envelope add mode, period
NR13 FF13 FFFF FFFF Frequency LSB
NR14 FF14 TL-- -FFF Trigger, Length enable, Frequency MSB

Square 2
     FF15 ---- ---- Not used
NR21 FF16 DDLL LLLL Duty, Length load (64-L)
NR22 FF17 VVVV APPP Starting volume, Envelope add mode, period
NR23 FF18 FFFF FFFF Frequency LSB
NR24 FF19 TL-- -FFF Trigger, Length enable, Frequency MSB
*/


let GB_CLOCK_HZ = 4194304.0
let SAMPLES_PER_PULSE_WAVE_PERIOD = 8.0


/// (Almost) Everything it takes to hook up a channel to a synthesizer
protocol SynthPluggable {
    associatedtype OscillatorType
    associatedtype MixerType
    
    func getSynthOscillator() -> OscillatorType
    func getSynthMixer() -> MixerType
    
    // Update the synth type's duty using the Game Boy native duty
    func updateSynthChannelDuty()
    func muteSynthChannelOutput()
    func unmuteSynthChannelOutput()
    func updateSynthChannelVolume()
    func updateSynthChannelFrequency()
}

protocol HasMusicalProperties {
    func getMusicalFrequency() -> Double
    func getMusicalAmplitude() -> Double // [0.0, 1.0]
}


/** Representation of a Game Boy pulse wave channel */
public class Pulse: HasLengthCounter, HasVolumeEnvelope {
    
    /** Constants */
    static let MIN_DUTY: UInt8 = 0
    static let MAX_DUTY: UInt8 = 3
    static let MIN_LENGTH_ENABLE: UInt8 = 0
    static let MAX_LENGTH_ENABLE: UInt8 = 1
    static let MIN_VOLUME: UInt8 = 0
    static let MAX_VOLUME: UInt8 = 15
    static let MIN_FREQUENCY: UInt16 = 0
    static let MAX_FREQUENCY: UInt16 = 2047
    
    
    /* DUTY CYCLE STUFF
        The pulse channel has a variable-width duty cycle */
    /** Duty is a two-bit value representing the pulse wave duty cycle to output */
    public var duty: UInt8 = Pulse.MIN_DUTY {
        didSet {
            if duty < Pulse.MIN_DUTY || duty > Pulse.MAX_DUTY {
                print("FATAL: invalid duty assigned")
                exit(1)
            }
            
            self.updateSynthChannelDuty()
        }
    }
    // Duty 0b00 is a 12.5% pulse; 0b01 is a 25% pulse; 0b10 -> 50%; 0b11 -> 75%
    static let wavetables: [[UInt]] = [[0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 1],
                                       [1, 0, 0, 0, 0, 1, 1, 1], [0, 1, 1, 1, 1, 1, 1, 0]]
    
    
    
    /* LENGTH STUFF
        At 256Hz: check if the length enabled flag is set, and decrement length if so
        If length transitions to 0, the channel gets disabled (by clearing an internal enabled flag) */
    
    /** lengthCounterLoad is a six-bit value that, when written to, sets the internal length counter */
    var lengthCounterLoad: UInt8 = 0 {
        didSet {
            self.lengthCounter.load(lengthCounterLoad)
        }
    }
    /** lengthCounter is an internal six-bit counter that, when fired, disables the channel */
    fileprivate var lengthCounter: Counter<UInt8> = Counter(value: 0, maxValue: 63, onFire: nil)
    
    fileprivate func lengthCounterFired() {
        self.enabled = false
    }
    
    /** lengthEnable is a one-bit value representing whether or not the length counter will actually decrement when clocked */
    var lengthEnable: UInt8 = 0 {
        didSet {
            // Validate range
            if lengthEnable < Pulse.MIN_LENGTH_ENABLE || lengthEnable > Pulse.MAX_LENGTH_ENABLE {
                print("FATAL: invalid length enable loaded: \(lengthEnable)")
                exit(1)
            }
        }
    }
    
    
    
    /* VOLUME STUFF */
    
    /** startingVolume is a 4-bit value that sets the initial volume of the channel 
        (initial meaning before any volume sweeping). */
    var startingVolume: UInt8 = Pulse.MIN_VOLUME {
        didSet {
            // Validate range
            if startingVolume < Pulse.MIN_VOLUME || startingVolume > Pulse.MAX_VOLUME {
                print("FATAL: invalid starting volume assigned: \(startingVolume)")
                exit(1)
            }
        }
    }
    /** volume is an internal 4-bit value that controls the output volume of the channel.
        It is the product of startingVolume plus any volume sweeping effects over time. */
    var volume: UInt8 = Pulse.MIN_VOLUME {
        didSet {
            updateSynthChannelVolume()
        }
    }
    
    /** envelopeAddMode specifies whether the volume goes up or down when the envelope counter fires */
    var envelopeAddMode: UInt8 = 0
    
    /** envelopePeriod specifies how many times the envelope clock needs to raise before the envelope triggers */
    var envelopePeriod: UInt8 = 0
    
    /** envelopeCounter is an internal four-bit counter that, when fired, changes the internal channel volume
        according to envelopeAddMode */
    fileprivate var envelopeCounter: Counter<UInt8> = Counter(value: 0, maxValue: 7, onFire: nil)
    
    /** Registered as the callback of envelopeCounter */
    fileprivate func envelopeCounterFired() {
        switch self.envelopeAddMode {
        case 0:
            if self.volume > Pulse.MIN_VOLUME {
                self.volume -= 1
            }
        case 1:
            if self.volume < Pulse.MAX_VOLUME {
                self.volume += 1
            }
        default:
            print("FATAL: invalid add mode!")
            exit(1)
        }
    }
    
    
    
    /* FREQUENCY STUFF */
    /** frequency is an 11-bit value representing the frequency timer period: that is, how long the channel
        stays on each sample of its wavetable, in 1/4194304ths of a second.
        The frequency of the output pulse wave is (4194304 / 8 / (2048-frequency)), since the wavetable is
        8 samples wide. */
    var frequency: UInt16 = 1192 {
        didSet {
            if frequency < Pulse.MIN_FREQUENCY || frequency > Pulse.MAX_FREQUENCY {
                print("FATAL: invalid frequency assigned: \(frequency)")
                exit(1)
            }
            
            updateSynthChannelFrequency()
        }
    }
    
    /* FREQUENCY SWEEP STUFF */
    /** Pulse 1 supports frequency sweeping */
    fileprivate let hasFrequencySweep: Bool
    
    var frequencySweepPeriod: UInt8 = 0
    var frequencySweepNegate: UInt8 = 0
    var frequencySweepShift: UInt8 = 0
    fileprivate var frequencySweepCounter: UInt8 = 0 //@todo make this a Counter
    fileprivate var frequencySweepEnabled: Bool = false
    fileprivate var frequencyShadow: UInt16 = 1192
    fileprivate var nextFrequency: UInt16 {
        get {
            let shifted = self.frequencyShadow >> UInt16(self.frequencySweepShift)
            var newFreq: UInt16
            
            if self.frequencySweepNegate == 0 {
                newFreq = self.frequencyShadow &+ shifted
            } else if self.frequencySweepNegate == 1 {
                newFreq = self.frequencyShadow &- shifted
            } else {
                print("FATAL: invalid frequency shift negate!")
                exit(1)
            }
            
            return newFreq
        }
    }
    fileprivate func frequencyOverflowCheck() {
        let newFrequency = self.nextFrequency
        if newFrequency > Pulse.MAX_FREQUENCY {
            self.enabled = false
        }
    }
    func sweepTimerFired() {
        if self.frequencySweepCounter == 0 {
            self.frequencySweepCounter = self.frequencySweepPeriod
        }
        
        if self.frequencySweepCounter == 0 {
            return
        }
        
        self.frequencySweepCounter -= 1
        
        if self.frequencySweepCounter == 0 {
            self.frequencyOverflowCheck()
            if self.frequencySweepShift != 0 {
                //@todo this actually writes back to NR1x
                self.frequency = self.nextFrequency
                self.frequencyShadow = self.frequency
                self.frequencyOverflowCheck()
            }
        }
    }
    
    
    
    /* TRIGGER STUFF */
    /** Trigger is a 1-bit value that, when set, 
        1. Raises the internal enable flag
        2. Sets length counter to max, if it's currently zero
        3. Reloads the frequency timer with period
        4. Reloads the volume envelope timer with period
        5. Reloads the channel volume
        6. Raises noise channel's LFSR bits
        7. Resets wave channel's table position
        8. Stuff for pulse 1's frequency sweep... */
    var trigger: UInt8 = 0 {
        didSet {
            if trigger == 1 {
                self.triggered()
            }
        }
    }
    
    fileprivate func triggered() {
        // 1. Raises the internal enable flag
        self.enabled = true
        
        // 2. If length counter is currently zero, set it to max
        self.lengthCounter.resetIfFired()
        
        // Maybe enable the length counter too?
        self.lengthEnable = 1
        
        // 3. Reloads the frequency timer with period
        //@todo we would need model frequency more accurately than AudioKit allows to do anything here
        
        // 4. Reloads the volume envelope timer with period
        self.envelopeCounter.load(self.envelopePeriod)
        
        // 5. Reloads the channel volume
        self.volume = self.startingVolume
        
        // 6. Raises noise channel's LFSR bits
        // 7. Resets wave channel's table position
        
        // 8. Stuff for pulse 1's frequency sweep
        if self.hasFrequencySweep {
            self.frequencyShadow = self.frequency
            
            self.frequencySweepCounter = self.frequencySweepPeriod
            
            if self.frequencySweepPeriod != 0 || self.frequencySweepShift != 0 {
                self.frequencySweepEnabled = true
            } else {
                self.frequencySweepEnabled = false
            }
            
            if self.frequencySweepShift != 0 {
                self.frequencyOverflowCheck()
            }
        }
        
        return
    }
    
    
    
    /** INTERNAL REGISTERS */
    fileprivate var enabled: Bool = true {
        didSet {
            if !enabled {
                muteSynthChannelOutput()
            } else {
                unmuteSynthChannelOutput()
            }
        }
    }
    
    
    func clock256() {
        if self.enabled {
            if self.lengthEnable > 0 {
                self.lengthCounter.clock()
            }
        }
    }
    
    func clock64() {
        if self.enabled {
            self.envelopeCounter.clock()
        }
    }
    
    
    
    /* NON-HARDWARE STUFF */
    /* Logic for hooking up to our synthesizer of choice (AudioKit) */
    /* (SynthPluggable support) */
    var oscillator: AKMorphingOscillator
    var mixer: AKMixer
    
    // AudioKit represents wavetables as arrays of floats of value [-1.0, 1.0]
    static let wavetablesAsInts: [[Int]] = Pulse.wavetables.map({ arr in arr.map({ val in Int(val) })})
    static let wavetablesAsFloats: [[Float]] = Pulse.wavetablesAsInts.map({ arr in arr.map({ val in Float(val*2-1) })})
    var akTables: [AKTable]
    
    
    init(mixer: AKMixer, hasFrequencySweep: Bool, connected: Bool) {
        //@todo there must be a better way to do this
        self.akTables = [AKTable(.square, count: 8), AKTable(.square, count: 8),
                         AKTable(.square, count: 8), AKTable(.square, count: 8)]
        var i = 0
        for pattern in Pulse.wavetablesAsFloats {
            //@todo hardcoded value
            for j in 0...7 {
                akTables[i][j] = pattern[j]
            }
            i = i+1
        }
        
        self.hasFrequencySweep = hasFrequencySweep
        
        self.oscillator = AKMorphingOscillator(waveformArray: akTables, amplitude: 1.0)
        self.mixer = mixer
        
        if connected {
            self.mixer.connect(self.oscillator)
        }
        self.oscillator.start()
    }
    
    //@todo this is a hack. how can we pass in our blocks to the counter constructors in our init?
    func initializeCounterCallbacks() {
        self.lengthCounter.onFire = self.lengthCounterFired
        self.envelopeCounter.onFire = self.envelopeCounterFired
    }
    
    convenience init(mixer: AKMixer) {
        self.init(mixer: mixer, hasFrequencySweep: false, connected: true)
    }
}

extension Pulse: HasMusicalProperties {
    public func getMusicalFrequency() -> Double {
        if frequency == 0 {
            return 0
        }
        
        //@todo this is channel type-specific
        //@todo magic numbers
        return (GB_CLOCK_HZ / SAMPLES_PER_PULSE_WAVE_PERIOD) / Double((2048-frequency)) / 4
    }
    
    public func getMusicalAmplitude() -> Double {
        if volume <= Pulse.MAX_VOLUME {
            return Double(volume) / Double(Pulse.MAX_VOLUME)
        }
        
        return 1.0
    }
}

// Functions used to output the pulse channel using AudioKit
extension Pulse: SynthPluggable {
    func getSynthOscillator() -> AKMorphingOscillator {
        return self.oscillator
    }
    
    func getSynthMixer() -> AKMixer {
        return self.mixer
    }
    
    func updateSynthChannelDuty() {
        /** Update the duty cycle (bit pattern) of this channel */
        self.oscillator.index = Double(self.duty)
    }
    
    func muteSynthChannelOutput() {
        /** Mute this channel */
        self.oscillator.amplitude = 0.0
    }
    
    func unmuteSynthChannelOutput() {
        /** Unmute this channel */
        self.updateSynthChannelVolume()
    }
    
    func updateSynthChannelVolume() {
        /** Update the volume of this channel */
        self.oscillator.amplitude = self.getMusicalAmplitude()
    }
    
    func updateSynthChannelFrequency() {
        /** Update the frequency of this channel */
        self.oscillator.frequency = self.getMusicalFrequency()
    }
}

// Utility functions: functions that don't mimic hardware, but are provided for
// convenience of emulation
extension Pulse {
    func alterConnection(connected: Bool) {
        if connected {
            oscillator.start()
        } else {
            oscillator.stop()
        }
    }
}

