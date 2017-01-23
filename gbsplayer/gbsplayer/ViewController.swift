//
//  ViewController.swift
//  gbsplayer
//
//  Created by Ryan Conway.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Cocoa
import AudioKit


let CASTLEVANIA_GBS_PATH: String = "/Users/owner/Dropbox/emu/castlevania.gbs" // works through
let DOUBLEDRAGON_GBS_PATH: String = "/Users/owner/Dropbox/emu/doubledragon.gbs" // track 4 is sick. works through
let TETRIS_GBS_PATH: String = "/Users/owner/Dropbox/emu/tetris.gbs" // works through
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/sml.gbs" // track 5 barfs. lots of reads to 0x0000 and 0x0001
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/batman.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/drmario.gbs" // seems to work through
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/tmnt.gbs"
//let GBS_PATH: String = "/Users/owner/Dropbox/emu/ducktales.gbs"


class ViewController: NSViewController {
    let player = GBSPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        player.loadGBSFile(path: TETRIS_GBS_PATH)
        player.playTrack(track: 0)
        sleep(2)
        
        player.loadGBSFile(path: DOUBLEDRAGON_GBS_PATH)
        player.playTrack(track: 4)
        sleep(2)
        
        player.loadGBSFile(path: TETRIS_GBS_PATH)
        player.playTrack(track: 0)
        sleep(2)
        
        player.loadGBSFile(path: CASTLEVANIA_GBS_PATH)
        player.playTrack(track: 0)
        sleep(2)
        
        player.loadGBSFile(path: DOUBLEDRAGON_GBS_PATH)
        player.playTrack(track: 4)
        sleep(2)
        
        player.loadGBSFile(path: TETRIS_GBS_PATH)
        player.playTrack(track: 0)
        sleep(2)

        
        
        
    }
}


