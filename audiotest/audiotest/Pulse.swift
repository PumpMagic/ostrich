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

func delay(delay: Int64, closure: ()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay)
        ),
        dispatch_get_main_queue(), closure)
}

/** Representation of a Game Boy pulse wave channel */
class Pulse {
    
    static let MIN_DUTY: UInt8 = 0
    static let MAX_DUTY: UInt8 = 3
    static let MIN_LENGTH_COUNTER: UInt8 = 0
    static let MAX_LENGTH_COUNTER: UInt8 = 63
    static let MIN_LENGTH_ENABLE: UInt8 = 0
    static let MAX_LENGTH_ENABLE: UInt8 = 1
    static let MIN_VOLUME: UInt8 = 0
    static let MAX_VOLUME: UInt8 = 15
    
    /* DUTY CYCLE STUFF
        The pulse channel has a variable-width duty cycle */
    /** Duty is a two-bit value representing the pulse wave duty cycle to output */
    var duty: UInt8 = Pulse.MIN_DUTY {
        didSet {
            if duty < Pulse.MIN_DUTY || duty > Pulse.MAX_DUTY {
                print("FATAL: invalid duty assigned")
                exit(1)
            }
            
            self.oscillator.index = Double(duty)
        }
    }
    // Duty 00 is a 12.5% pulse; 01 is a 25% pulse; 10 50%; 11 75%
    static let wavetables: [[UInt]] = [[0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 1],
                                       [1, 0, 0, 0, 0, 1, 1, 1], [0, 1, 1, 1, 1, 1, 1, 0]]
    
    
    
    /* LENGTH STUFF
        At 256Hz: check if the length enabled flag is set, and decrement length if so
        If length transitions to 0, the channel gets disabled (by clearing an internal enabled flag) */
    
    /** lengthCounterLoad is a six-bit value that, when written to, sets the internal length counter */
    var lengthCounterLoad: UInt8 = Pulse.MIN_LENGTH_COUNTER {
        didSet {
            if lengthCounterLoad < Pulse.MIN_LENGTH_COUNTER || lengthCounterLoad > Pulse.MAX_LENGTH_COUNTER {
                print("FATAL: invalid length loaded: \(lengthCounterLoad)")
                exit(1)
            }
            
            self.lengthCounter = lengthCounterLoad
        }
    }
    /** lengthCounter is an internal six-bit vaule representing the time, in 1/256ths of a second, after which the
     channel should be disabled */
    internal var lengthCounter: UInt8 = 0 {
        didSet {
            if lengthCounter == Pulse.MIN_LENGTH_COUNTER {
                self.enabled = false
            }
        }
    }
    
    /** lengthEnableLoad is a one-bit value that, when written to, sets the internal length enable */
    var lengthEnableLoad: UInt8 = 0 {
        didSet {
            if lengthEnableLoad < Pulse.MIN_LENGTH_ENABLE || lengthEnableLoad > Pulse.MIN_LENGTH_ENABLE {
                print("FATAL: invalid length enable loaded: \(lengthEnableLoad)")
                exit(1)
            }
            
            self.lengthEnable = lengthEnableLoad
        }
    }
    /** Length Enable is a one-bit value representing whether or not the Length machinery should run */
    internal var lengthEnable: UInt8 = 0
    
    func lengthTimerFired() {
        if lengthEnable == 1 {
            if lengthCounter > 0 {
                lengthCounter -= 1
            }
        }
    }
    
    
    
    /* VOLUME STUFF */
    
    /** volumeLoad is a 4-bit value that sets the initial volume of the channel */
    var volumeLoad: UInt8 = Pulse.MIN_VOLUME {
        didSet {
            if volumeLoad < Pulse.MIN_VOLUME || volumeLoad > Pulse.MAX_VOLUME {
                print("FATAL: invalid volume assigned: \(volumeLoad)")
                exit(1)
            }
            
            self.volume = volumeLoad
        }
    }
    /** volume is an internal 4-bit value that controls the output volume of the channel */
    internal var volume: UInt8 = Pulse.MIN_VOLUME {
        didSet {
            updateImplVolume()
        }
    }
    
    /** Envelope add mode specifies whether the volume goes up or down when the envelope counter fires */
    var envelopeAddMode: UInt8 = 0
    
    /** Envelope period specifies how many times the envelope clock needs to fire before the envelope triggers */
    var envelopePeriod: UInt8 = 0
    internal var envelopeCounter: UInt8 = 0
    
    func envelopeTimerFired() {
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
    var trigger: UInt8 = 0 {
        didSet {
            if trigger == 1 {
                self.triggered()
            }
        }
    }
    
    internal func triggered() {
        // 1. Raises the internal enable flag
        self.enabled = true
        
        // 2. If length counter is currently zero, set it to max
        if self.lengthCounter == Pulse.MIN_LENGTH_COUNTER {
            self.lengthCounter = Pulse.MAX_LENGTH_COUNTER
        }
        
        // 3. Reloads the frequency timer with period
        //@todo we would need model frequency more accurately than AudioKit allows to do anything here
        
        // 4. Reloads the volume envelope timer with period
        self.envelopeCounter = self.envelopePeriod
        
        // 5. Reloads the channel volume
        self.volume = self.volumeLoad
        
        // 6. Raises noise channel's LFSR bits
        // 7. Resets wave channel's table position
        // 8. Stuff for pulse 1's frequency sweep...
        
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
        let newFrequency = toImplFrequency(self.frequency)
        
        self.oscillator.frequency = newFrequency
    }
    
    // AudioKit represents wavetables as arrays of floats of value [-1.0, 1.0]
    static let wavetablesAsInts: [[Int]] = Pulse.wavetables.map({ arr in arr.map({ val in Int(val) })})
    static let wavetablesAsFloats: [[Float]] = Pulse.wavetablesAsInts.map({ arr in arr.map({ val in Float(val*2-1) })})
    var akTables: [AKTable]
    
    
    init(mixer: AKMixer, connected: Bool) {
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
        
        if connected {
            self.mixer.connect(self.oscillator)
        }
        self.oscillator.start()
    }
    
    convenience init(mixer: AKMixer) {
        self.init(mixer: mixer, connected: true)
    }
}