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
        
        let _ = ApuTest()
    }
}

class ApuTest {
    var cpu: LR35902
    var header: GBSHeader
    var codeAndData: NSData
    
    init() {
        guard let (theHeader, theCodeAndData) = parseFile(GBS_PATH) else {
            exit(1)
        }
        
        self.header = theHeader
        self.codeAndData = theCodeAndData
        
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
        // internal RAM: 0xC000 - 0xCFFF plus switchable RAM (need to implement banking): 0xD000 - 0xDFFF
        let internalRAM = RAM(size: 0xE000 - 0xC000, fillByte: 0x00, firstAddress: 0xC000)
        // cartridge RAM: 0xA000 - 0xBFFF (need to add this conditionally)
        let cartridgeRAM = RAM(size: 0xC000 - 0xA000, fillByte: 0x00, firstAddress: 0xA000)
        // high RAM: 0xFF80 - 0xFFFE
        let highRAM = RAM(size: 0xFFFF - 0xFF80, fillByte: 0x00, firstAddress: 0xFF80)
        let rom = ROM(data: codeAndData, firstAddress: header.loadAddress)
        let apu = GameBoyAPU(mixer: mixer)
        
        AudioKit.start()
        
        let bus = DataBus()
        bus.registerReadable(rom)
        bus.registerReadable(internalRAM)
        bus.registerWriteable(internalRAM)
        bus.registerReadable(cartridgeRAM)
        bus.registerWriteable(cartridgeRAM)
        bus.registerReadable(highRAM)
        bus.registerWriteable(highRAM)
        bus.registerReadable(apu)
        bus.registerWriteable(apu)
        
        cpu = LR35902(bus: bus)
        
        cpu.setSP(header.stackPointer)
        cpu.setPC(header.loadAddress)
        
        /* INIT - Called at the end of the LOAD process, or when a new song is selected.
         All of the registers are initialized, RAM is cleared, and the init address is
         called with the song number set in the accumulator. Note that the song number
         in the accumulator is zero-based (the first song is 0). The init code must end
         with a RET instruction. */
        print("Calling and running INIT...")
        cpu.setA(header.firstSong)
        cpu.injectCall(header.initAddress)
        cpu.runUntilRet()
        
        /* PLAY - Begins after INIT process is complete. The play address is constantly
         called at the rate established in the header (see TIMING). The play code must
         end with a RET instruction. */
        //@todo use a software timer to call this repeatedly according to timerModulo / timerControl
        print("Calling and running PLAY...")
        
        let _ = NSTimer.scheduledTimerWithTimeInterval(0.167, target: self, selector: #selector(ApuTest.vblank), userInfo: nil, repeats: true)
    }
    
    @objc func vblank() {
        cpu.injectCall(header.playAddress)
        cpu.runUntilRet()
    }
}