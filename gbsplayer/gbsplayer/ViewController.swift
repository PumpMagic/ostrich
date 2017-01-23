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
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/sml.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/doubledragon.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/castlevania.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/batman.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/drmario.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/tmnt.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/ducktales.gbs"


class ViewController: NSViewController {
    let player = GBSPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player.loadGBSFile(path: GBS_PATH)
        
        // Play each track for a few seconds
        var track: UInt8 = 0
        while true {
            print("Loading track \(track)")
            
            player.playTrack(track: track)
            //@todo shouldn't need to adjust volume after starting a track
            player.setVolume(level: 1.0)
            sleep(10)
            player.stopPlaying()
            track += 1
        }
    }
}


