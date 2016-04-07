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

protocol HasFrequency {
    var frequency: UInt16 { get set }
}

protocol HasVolumeEnvelope {
    var volume: UInt8 { get set }
}

protocol HasLengthTimer {
    var length: UInt8 { get set }
    var lengthEnable: Bool { get set }
}

func delay(delay: Int64, closure: ()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay)
        ),
        dispatch_get_main_queue(), closure)
}

/** Representation of a Game Boy pulse wave channel */
class Pulse: HasFrequency, HasVolumeEnvelope, HasLengthTimer {
    /* DUTY CYCLE STUFF
        The pulse channel has a variable-width duty cycle */
    /** Duty is a two-bit value representing the pulse wave duty cycle to output */
    var duty: UInt8 = 0 {
        didSet {
            //@todo enforce range
            self.oscillator.index = Double(duty)
        }
    }
    // Duty 00 is a 12.5% pulse; 01 is a 25% pulse; 10 50%; 11 75%
    static let wavetables: [[UInt]] = [[0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 1],
                                       [1, 0, 0, 0, 0, 1, 1, 1], [0, 1, 1, 1, 1, 1, 1, 0]]
    
    
    
    /* LENGTH STUFF
        Every 256hz, if the length enabled flag is set, length gets decremented
        If length transitions to 0, the channel gets disabled (by clearing an internal enabled flag) */
    /** Length is a six-bit vaule representing the time, in 1/256ths of a second, after which the
        channel should be disabled */
    var length: UInt8 = 0 {
        didSet {
            if length == 0 {
                self.enabled = false
            }
        }
    }
    
    static let LENGTH_TIMER_PERIOD: Int64 = 3906250 //ns of 1/256 sec
    
    /** Length Enable is a one-bit value representing whether or not the Length machinery should run */
    var lengthEnable: Bool = false
    
    internal func lengthTimerFired() {
        if lengthEnable {
            if length > 0 {
                length = length - 1
            }
        }
        
        delay(Pulse.LENGTH_TIMER_PERIOD) {
            self.lengthTimerFired()
        }
    }
    
    
    
    /* VOLUME STUFF */
    /** Volume is a 4-bit value representing the volume of the channel */
    var volume: UInt8 = 0 {
        didSet {
            //@todo enforce range
            updateImplVolume()
        }
    }
    
    
    
    /* FREQUENCY STUFF */
    /** Frequency is an 11-bit value representing the frequency timer period: that is, how long the channel
        stays on each sample of its wavetable, in 1/4194304ths of a second.
        The frequency of the output pulse wave is (4194304 / 8 / frequency), since the wavetable is
        8 samples wide  */
    var frequency: UInt16 = 1192 {
        didSet {
            updateImplFrequency()
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
    var trigger: Bool = false {
        didSet {
            if trigger == true {
                self.triggered()
            }
        }
    }
    
    internal func triggered() {
        //@todo see comment block for trigger variable above
        return
    }
    
    
    
    /** INTERNAL REGISTERS */
    internal var enabled: Bool = true {
        didSet {
            if !enabled {
                self.oscillator.amplitude = 0.0
            } else {
                updateImplVolume()
            }
        }
    }
    
    
    
    /* INTERNAL IMPLEMENTATION (AUDIOKIT) STUFF */
    internal var oscillator: AKMorphingOscillator
    internal var mixer: AKMixer
    
    /** Update the volume of this channel to whatever audio library we're using */
    func updateImplVolume() {
        self.oscillator.amplitude = toImplAmplitude(self.volume)
    }
    
    /** Update the frequency of this channel to whatever audio library we're using */
    func updateImplFrequency() {
        self.oscillator.frequency = toImplFrequency(self.frequency)
    }
    
    // AudioKit represents wavetables as arrays of floats of value [-1.0, 1.0]
    static let wavetablesAsInts: [[Int]] = Pulse.wavetables.map({ arr in arr.map({ val in Int(val) })})
    static let wavetablesAsFloats: [[Float]] = Pulse.wavetablesAsInts.map({ arr in arr.map({ val in Float(val*2-1) })})
    var akTables: [AKTable]
    
    
    init(mixer: AKMixer) {
        //@todo there must be a better way to do this
        self.akTables = [AKTable(.Square, size: 8), AKTable(.Square, size: 8),
                         AKTable(.Square, size: 8), AKTable(.Square, size: 8)]
        var i = 0
        for pattern in Pulse.wavetablesAsFloats {
            akTables[i].values = pattern
            i = i+1
        }
        
        self.oscillator = AKMorphingOscillator(waveformArray: akTables, amplitude: 1.0)
        self.mixer = mixer
        
        self.mixer.connect(self.oscillator)
        self.oscillator.start()
        
        
        // Start length timer
        self.lengthTimerFired()
    }
}