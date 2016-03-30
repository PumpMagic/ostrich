//
//  ViewController.swift
//  ostrich
//
//  Created by Ryan Conway on 3/29/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Cocoa
import ostrichframework


class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ROM_PATH: String = "/Users/ryan.conway/Dropbox/emu/SML.gb"
        
        guard let rawData = NSData(contentsOfFile: ROM_PATH) else {
            print("Unable to find rom at \(ROM_PATH)")
            exit(1)
        }
        
        print("Found rom at \(ROM_PATH)")
        print("The rom is \(rawData.length) bytes long")
        
        let myRom = Memory(data: rawData)
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

        
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

