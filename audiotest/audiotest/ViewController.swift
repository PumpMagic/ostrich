//
//  ViewController.swift
//  HelloWorld
//
//  Created by Ryan Conway.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Cocoa
import AudioKit
import ostrichframework


let GBS_PATH: String = "/Users/ryanconway/Dropbox/emu/SML.gbs"

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let (header, codeAndData) = parseFile(GBS_PATH) else {
            exit(1)
        }
        
        print(header)
        
        let myRom = Memory(data: codeAndData)
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
        
        /*
        let mixer = AKMixer()
        let apu = GameBoyAPU(mixer: mixer)
        AudioKit.output = mixer
        AudioKit.start()
        
        
        apu.pulse1.duty = 0
        apu.pulse2.enabled = false
        
        apu.pulse1.frequency = 1192
        apu.pulse1.volume = 15
        usleep(2000000)
        
        apu.pulse1.frequency = 1061
        apu.pulse1.volume = 8
        usleep(2000000)
        
        apu.pulse1.frequency = 1002
        apu.pulse1.volume = 2
        usleep(2000000)
        */
        
        
        
        exit(1)
    }
}

