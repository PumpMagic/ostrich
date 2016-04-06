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
        
        /* LOAD - The ripped code and data is read into the player program's address space
             starting at the load address and proceeding until end-of-file or address $7fff
             is reached. After loading, Page 0 is in Bank 0 (which never changes), and Page
             1 is in Bank 1 (which can be changed during init or play). Finally, the INIT
             is called with the first song defined in the header. */
        print("Instantiating Z80 and executing LOAD...")
        let rom = ROM(data: codeAndData, startingAddress: header.loadAddress)
        let z80 = Z80(rom: rom)
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
        z80.injectCall(header.playAddress)
        z80.runUntil("RET")
        
        
        exit(1)
    }
}

