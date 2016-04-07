//
//  LR35902.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/6/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Representation of a Sharp LR35902 CPU.
public class LR35902: Intel8080Like {
    // main registers
    /// A, AKA the Accumulator
    let A: Register8
    let B: Register8
    let C: Register8
    let D: Register8
    let E: Register8
    /// F, aka the Flags
    let F: Register8
    let H: Register8
    let L: Register8
    
    /// stack pointer
    let SP: Register16
    
    // other registers
    /// interrupt page address
    let I: Register8
    /// memory refresh
    let R: Register8
    
    /// program counter
    let PC: Register16
    
    // flags - computed from F
    /// Zero flag
    let ZF: Flag
    /// Ssubtract flag
    let NF: Flag
    /// Half-carry flag
    let HF: Flag
    /// Carry flag
    let CF: Flag
    
    // logical 16-bit main registers
    let AF: Register16Computed
    let BC: Register16Computed
    let DE: Register16Computed
    let HL: Register16Computed
    
    /// interrupt
    var IFF1: FlipFlop
    var IFF2: FlipFlop
    
    var instructionContext: Intel8080InstructionContext
    
    let bus: DataBus
    
    public init(bus: DataBus) {
        self.A = Register8(val: 0)
        self.B = Register8(val: 0)
        self.C = Register8(val: 0)
        self.D = Register8(val: 0)
        self.E = Register8(val: 0)
        self.F = Register8(val: 0)
        self.H = Register8(val: 0)
        self.L = Register8(val: 0)
        
        self.SP = Register16(val: 0)
        
        self.I = Register8(val: 0)
        self.R = Register8(val: 0)
        
        self.PC = Register16(val: 0x100) //@todo don't init this here
        
        self.ZF = Flag(reg: F, bitNumber: 7)
        self.NF = Flag(reg: F, bitNumber: 6)
        self.HF = Flag(reg: F, bitNumber: 5)
        self.CF = Flag(reg: F, bitNumber: 4)
        
        self.AF = Register16Computed(high: self.A, low: self.F)
        self.BC = Register16Computed(high: self.B, low: self.C)
        self.DE = Register16Computed(high: self.D, low: self.E)
        self.HL = Register16Computed(high: self.H, low: self.L)
        
        self.IFF1 = .Disabled
        self.IFF2 = .Disabled
        
        self.instructionContext = Intel8080InstructionContext(lastInstructionWasEI: false)
        
        self.bus = bus
    }
    
    // Utility methods
    public func setSP(sp: Address) {
        self.SP.write(sp)
    }
    
    public func setPC(pc: Address) {
        self.PC.write(pc)
    }
    
    public func setA(a: UInt8) {
        self.A.write(a)
    }
    
    public func injectCall(addr: Address) {
        let instruction = CALL(condition: nil, dest: Immediate16(val: addr))
        instruction.runOn(self)
    }
    
    /// Stack pointer and program counter debug string
    var pcsp: String { return "\tSP: \(self.SP.read().hexString)\n\tPC: \(self.PC.read().hexString)" }
    
    
    public func runUntil(instructionType: String) {
        //@todo this is a hacky convenience function, how can we better detect a given instruction without inspecting type?
        var iteration = 1
        repeat {
            let lastInstruction = doInstructionCycle()
            iteration += 1
            let inspectedType = String(Mirror(reflecting: lastInstruction).subjectType)
            if inspectedType == instructionType {
                return
            }
        } while true
    }
    
    
    /// Fetches an instruction, runs it, and returns it
    public func doInstructionCycle() -> Instruction {
        guard let instruction = self.fetchInstruction() else {
            print("FATAL: unable to fetch instruction")
            exit(1)
        }
        self.executeInstruction(instruction)
        
        return instruction
    }
    
    /// Execute an instruction.
    /// This function has some additional behavior to support things like EI, which has effects delayed by an instruction.
    func executeInstruction(instruction: Instruction) {
        let willEnableInterrupts = self.instructionContext.lastInstructionWasEI
        
        instruction.runOn(self)
        
        if willEnableInterrupts {
            self.IFF1 = .Enabled
            self.IFF2 = .Enabled
            
            //@warn this behavior may be too lazy
            self.instructionContext.lastInstructionWasEI = false
        }
    }
    
    //@todo make this internal and add a public run() or clock() or something
    func fetchInstruction() -> Instruction? {
        let firstByte = bus.read(PC.read())
        
        var instruction: Instruction? = nil
        var instructionLength: UInt16 = 1
        
        print(String(format: "Unrecognized opcode 0x%02X at PC 0x%04X", firstByte, PC.read()))
        
        //@warn we should probably only alter the PC if the instruction doesn't do so itself
        PC.write(PC.read() + instructionLength)
        return instruction
    }
}