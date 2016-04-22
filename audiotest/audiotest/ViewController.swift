//
//  ViewController.swift
//  audiotest
//
//  Created by Ryan Conway.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Cocoa
import AudioKit
import ostrichframework


let GBS_PATH: String = "/Users/ryan.conway/Dropbox/emu/tetris.gbs"


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
    
    init() {
        guard let (theHeader, theCodeAndData) = parseFile(GBS_PATH) else {
            exit(1)
        }
        
        self.header = theHeader
        self.codeAndData = theCodeAndData
        
        print("\(header)\n")
        
        // Instantiate some prep stuff
        let mixer = AKMixer()
        
        /* LOAD - The ripped code and data is read into the player program's address space
         starting at the load address and proceeding until end-of-file or address $7fff
         is reached. After loading, Page 0 is in Bank 0 (which never changes), and Page
         1 is in Bank 1 (which can be changed during init or play). Finally, the INIT
         is called with the first song defined in the header. */
        print("Instantiating LR35902 and peripherals and executing LOAD...")
        
        /// ROM: Generally 0x0000 - 0x3FFF and 0x4000 - 0x7FFF, but sometimes incomplete subregions of such
        /// (at least in the case of GBS files)
        let rom = ROM(data: codeAndData, firstAddress: header.loadAddress)
        
        // 0x8000 - 0x9FFF is unimplemented video stuff
        
        /// External (cartridge) RAM: 0xA000 - 0xBFFF
        /// @todo this exists only on a per-cartridge basis
        externalRAM = RAM(size: 0xC000 - 0xA000, fillByte: 0x00, firstAddress: 0xA000)
        
        /// Internal (work) RAM bank 0: 0xC000 - 0xCFFF
        /// Internal (work) RAM bank 1-7: 0xD000 - 0xDFFF
        //@todo implement bank switching to support CGB
        internalRAM = RAM(size: 0xE000 - 0xC000, fillByte: 0x00, firstAddress: 0xC000)
        
        // 0xE000 - 0xFDFF is reserved echo RAM
        
        // 0xFE00 - 0xFE9F is unimplemented video stuff
        
        // 0xFEA0 - 0xFEFF is unused
        
        // 0xFF00 - 0xFF7F is partially unimplemented hardware IO registers
        /// 0xFF10 - 0xFF3F is the APU memory
        apu = GameBoyAPU(mixer: mixer)
        
        /// 0xFF80 - 0xFFFE is high RAM
        let highRAM = RAM(size: 0xFFFF - 0xFF80, fillByte: 0x00, firstAddress: 0xFF80)
        
        bus = DataBus()
        bus.connectReadable(rom)
        bus.connectReadable(internalRAM)
        bus.connectWriteable(internalRAM)
        bus.connectReadable(externalRAM)
        bus.connectWriteable(externalRAM)
        bus.connectReadable(highRAM)
        bus.connectWriteable(highRAM)
        bus.connectReadable(apu)
        bus.connectWriteable(apu)
        
        cpu = LR35902(bus: bus)
        
        cpu.setSP(header.stackPointer)
        cpu.setPC(header.loadAddress)
        
        /* INIT - Called at the end of the LOAD process, or when a new song is selected.
         All of the registers are initialized, RAM is cleared, and the init address is
         called with the song number set in the accumulator. Note that the song number
         in the accumulator is zero-based (the first song is 0). The init code must end
         with a RET instruction. */
        print("Calling and running INIT...")
        cpu.setA(header.firstSong+2)
        cpu.call(header.initAddress)
        
        /* PLAY - Begins after INIT process is complete. The play address is constantly
         called at the rate established in the header (see TIMING). The play code must
         end with a RET instruction. */
        print("Calling and running PLAY...")
        
        //@todo listen to the GBS header's timerModulo and timerControl fields and set this timer accordingly
        NSTimer.scheduledTimerWithTimeInterval(0.00391, target: self, selector: #selector(ApuTest.clock256), userInfo: nil, repeats: true)
        
        AudioKit.output = mixer
        AudioKit.start()
    }
    
    var clockIndex = 0 // 0-3
    @objc func clock256() {
        apu.clock256()
        
        // 64Hz
        if clockIndex == 3 {
            cpu.call(header.playAddress)
        }
        
        clockIndex += 1
        if clockIndex > 3 {
            clockIndex = 0
        }
    }
}