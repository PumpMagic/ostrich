//
//  GameBoy.swift
//  ostrich
//
//  Created by Owner on 1/21/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Foundation
import AudioKit


/// A Nintendo Game Boy.
open class GameBoy {
    let cpu: LR35902
    let apu: GameBoyAPU
    let mixer: AKMixer
    
    let bus: DataBus
    let internalRAM: RAM
    let highRAM: RAM
    var rom: ROM?
    var externalRAM: RAM?
    
    
    init() {
        // 0x000 - 0x3FFF and 0x4000 - 0x7FFF are generally cartridge ROM
        // To insert a cartridge, call insertCartridge()
        self.rom = nil
        
        // 0x8000 - 0x9FFF is unimplemented video stuff
        
        // 0xA000 - 0xBFF is external (cartridge) RAM
        // Call insertCartridge() to populate external RAM
        self.externalRAM = nil
        
        /// Internal (work) RAM bank 0: 0xC000 - 0xCFFF
        /// Internal (work) RAM bank 1-7: 0xD000 - 0xDFFF
        //@todo implement bank switching to support CGB
        self.internalRAM = RAM(size: 0xE000 - 0xC000, fillByte: 0x00, firstAddress: 0xC000)
        
        // 0xE000 - 0xFDFF is reserved echo RAM
        
        // 0xFE00 - 0xFE9F is unimplemented video stuff
        
        // 0xFEA0 - 0xFEFF is unused
        
        // 0xFF00 - 0xFF7F is partially unimplemented hardware IO registers
        
        // 0xFF10 - 0xFF3F is the APU memory
        
        // Instantiate the APU and audio engine mixer
        self.mixer = AKMixer()
        self.apu = GameBoyAPU(mixer: self.mixer)
        
        // 0xFF80 - 0xFFFE is high RAM
        self.highRAM = RAM(size: 0xFFFF - 0xFF80, fillByte: 0x00, firstAddress: 0xFF80)
        
        self.bus = DataBus()
        self.bus.connectReadable(self.internalRAM)
        self.bus.connectWriteable(self.internalRAM)
        self.bus.connectReadable(self.highRAM)
        self.bus.connectWriteable(self.highRAM)
        self.bus.connectReadable(self.apu)
        self.bus.connectWriteable(self.apu)
        
        self.cpu = LR35902(bus: bus)

        // Start the audio engine
        AudioKit.output = mixer
        AudioKit.start()
    }
    
    //@todo don't allow inserting multiple cartridges
    func insertCartridge(rom: Data, romStartAddress: Address) {
        self.rom = ROM(data: rom, firstAddress: romStartAddress)
        
        // @todo this exists only on a per-cartridge basis
        // but we make it for everything right now
        self.externalRAM = RAM(size: 0xC000 - 0xA000, fillByte: 0x00, firstAddress: 0xA000)
        
        
        
        //@todo UNWRAP OPTIONALS PROPERLY
        self.bus.connectReadable(self.rom!)
        self.bus.connectReadable(self.externalRAM!)
        self.bus.connectWriteable(self.externalRAM!)
    }
    
    func setVolume(level: Double) {
        mixer.volume = level
    }
    
    
    //@todo support removing a cartridge
}
