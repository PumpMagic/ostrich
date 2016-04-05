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
        
        //@todo zero-pad codeAndData with loadAddress bytes?
        
        /* LOAD - The ripped code and data is read into the player program's address space
             starting at the load address and proceeding until end-of-file or address $7fff
             is reached. After loading, Page 0 is in Bank 0 (which never changes), and Page
             1 is in Bank 1 (which can be changed during init or play). Finally, the INIT
             is called with the first song defined in the header. */
        print("Executing LOAD...")
        let rom = ROM(data: codeAndData, startingAddress: header.loadAddress)
        let z80 = Z80(rom: rom)
        
        z80.setSP(header.stackPointer)
        z80.setPC(header.loadAddress)
        
        print("Calling INIT...")
        z80.injectCall(header.initAddress)
        
        /* INIT - Called at the end of the LOAD process, or when a new song is selected.
             All of the registers are initialized, RAM is cleared, and the init address is
             called with the song number set in the accumulator. Note that the song number
             in the accumulator is zero-based (the first song is 0). The init code must end
             with a RET instruction. */
        print("Executing INIT...")
        
        z80.runUntilRET()
        var iteration = 1
        repeat {
            guard let instruction = z80.fetchInstruction() else {
                print("Okay, bye")
                exit(1)
            }
            print("\(iteration): \(instruction)")
            instruction.runOn(z80)
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
         
        exit(1)
        */
    }
}

