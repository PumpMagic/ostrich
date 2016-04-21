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


let GBS_PATH: String = "/Users/ryanconway/Dropbox/emu/sml.gbs"


class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = ApuTest()
    }
}

class ApuTest {
    var cpu: LR35902
    var apu: GameBoyAPU
    var header: GBSHeader
    var codeAndData: NSData
    var bus: DataBus
    var externalRAM: RAM
    var internalRAM: RAM
    
    var clocks64: Int = 0
    
    init() {
        guard let (theHeader, theCodeAndData) = parseFile(GBS_PATH) else {
            exit(1)
        }
        
        self.header = theHeader
        self.codeAndData = theCodeAndData
        
        print("\(header)\n")
        
        // Instantiate some prep stuff
        let mixer = AKMixer()
        AudioKit.output = mixer
        
        /* LOAD - The ripped code and data is read into the player program's address space
         starting at the load address and proceeding until end-of-file or address $7fff
         is reached. After loading, Page 0 is in Bank 0 (which never changes), and Page
         1 is in Bank 1 (which can be changed during init or play). Finally, the INIT
         is called with the first song defined in the header. */
        print("Instantiating Z80 and executing LOAD...")
        
        /// ROM: Generally 0x0000 - 0x3FFF and 0x4000 - 0x7FFF, but sometimes incomplete subregions of such
        /// (at least in the case of GBS files)
        let rom = ROM(data: codeAndData, firstAddress: header.loadAddress)
        
        // 0x8000 - 0x9FFF is unimplemented video stuff
        
        /// External (cartridge) RAM: 0xA000 - 0xBFFF
        /// @todo this exists only on a per-cartridge basis
        externalRAM = RAM(size: 0xC000 - 0xA000, fillByte: 0x00, firstAddress: 0xA000)
        
        /// Internal RAM: 0xC000 - 0xCFFF plus switchable RAM (need to implement banking): 0xD000 - 0xDFFF
        internalRAM = RAM(size: 0xE000 - 0xC000, fillByte: 0x00, firstAddress: 0xC000)
        
        // 0xE000 - 0xFDFF is reserved echo RAM
        // 0xFE00 - 0xFE9F is unimplemented video stuff
        // 0xFEA0 - 0xFEFF is unused
        
        // 0xFF00 - 0xFF7F is partially unimplemented hardware IO registers
        /// 0xFF10 - 0xFF3F is the APU memory
        apu = GameBoyAPU(mixer: mixer)
        
        /// High RAM: 0xFF80 - 0xFFFE
        let highRAM = RAM(size: 0xFFFF - 0xFF80, fillByte: 0x00, firstAddress: 0xFF80)
        
        
        AudioKit.start()
        
        bus = DataBus()
        bus.registerReadable(rom)
        bus.registerReadable(internalRAM)
        bus.registerWriteable(internalRAM)
        bus.registerReadable(externalRAM)
        bus.registerWriteable(externalRAM)
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
        print("Calling and running PLAY...")
        
        //@todo listen to timerModulo / timerControl
        let _ = NSTimer.scheduledTimerWithTimeInterval(0.015625, target: self, selector: #selector(ApuTest.clock64), userInfo: nil, repeats: true)
        let _ = NSTimer.scheduledTimerWithTimeInterval(0.00391, target: self, selector: #selector(ApuTest.clock256), userInfo: nil, repeats: true)
//        let _ = NSTimer.scheduledTimerWithTimeInterval(0.15625, target: self, selector: #selector(ApuTest.clock64), userInfo: nil, repeats: true)
//        let _ = NSTimer.scheduledTimerWithTimeInterval(0.0391, target: self, selector: #selector(ApuTest.clock256), userInfo: nil, repeats: true)
    }
    
    @objc func clock64() {
        cpu.injectCall(header.playAddress)
        cpu.runUntilRet()
    }
    
    @objc func clock256() {
        apu.clock256()
    }
}