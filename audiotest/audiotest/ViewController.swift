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

func delayed(nanos: Int64, closure: () -> ()) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nanos), dispatch_get_main_queue(), closure)
}

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let (header, codeAndData) = parseFile(GBS_PATH) else {
            exit(1)
        }
        
        print(header)
        
        // Instantiate some prep stuff
        let mixer = AKMixer()
        AudioKit.output = mixer
        
        /* LOAD - The ripped code and data is read into the player program's address space
             starting at the load address and proceeding until end-of-file or address $7fff
             is reached. After loading, Page 0 is in Bank 0 (which never changes), and Page
             1 is in Bank 1 (which can be changed during init or play). Finally, the INIT
             is called with the first song defined in the header. */
        print("Instantiating Z80 and executing LOAD...")
        let ram = RAM(size: 0xE000 - 0xC000, fillByte: 0x00, firstAddress: 0xC000)
        let rom = ROM(data: codeAndData, firstAddress: header.loadAddress)
        let apu = GameBoyAPU(mixer: mixer)
        
        AudioKit.start()
        
        let bus = DataBus()
        bus.registerReadable(rom)
        bus.registerReadable(ram)
        bus.registerWriteable(ram)
        bus.registerReadable(apu)
        bus.registerWriteable(apu)
        
        let cpu = Z80(bus: bus)
        
        z80.setSP(header.stackPointer)
        z80.setPC(header.loadAddress)
        
        /* INIT - Called at the end of the LOAD process, or when a new song is selected.
             All of the registers are initialized, RAM is cleared, and the init address is
             called with the song number set in the accumulator. Note that the song number
             in the accumulator is zero-based (the first song is 0). The init code must end
             with a RET instruction. */
        print("Calling and running INIT...")
        z80.setA(header.firstSong)
        z80.injectCall(header.initAddress)
        z80.runUntil("RET")
        
        /* PLAY - Begins after INIT process is complete. The play address is constantly
             called at the rate established in the header (see TIMING). The play code must
             end with a RET instruction. */
        //@todo use a software timer to call this repeatedly according to timerModulo / timerControl
        print("Calling and running PLAY...")
        
        /*
        var closure: (Void -> Void)!
        closure = {
            print("Beep beep")
            z80.injectCall(header.playAddress)
            z80.runUntil("RET")
            delayed(16666666) { closure() }
        }
        
        closure()
        repeat { usleep(1000) } while true
        */
        
        repeat {
            z80.injectCall(header.playAddress)
            z80.runUntil("RET")
            usleep(16666)
        } while true
    }
}

