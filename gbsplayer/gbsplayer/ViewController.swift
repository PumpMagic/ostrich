//
//  ViewController.swift
//  audiotest
//
//  Created by Ryan Conway.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Cocoa
import AudioKit


let GBS_PATH: String = "/Users/owner/Dropbox/emu/tetris.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/doubledragon.gbs"


class ViewController: NSViewController {
    let player = GBSPlayer(path: GBS_PATH)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sleep(5)
        
        
        player.stopClocking()
        player.loadTrack(number: 0)
        sleep(1)
        player.startClocking()
    }
}


