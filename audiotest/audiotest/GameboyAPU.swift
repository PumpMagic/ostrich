//
//  GameboyAPU.swift
//  audiotest
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation
import AudioKit


class GameBoyAPU {
    let pulse1: Pulse
    let pulse2: Pulse
    
    init(mixer: AKMixer) {
        self.pulse1 = Pulse(mixer: mixer)
        self.pulse2 = Pulse(mixer: mixer)
    }
}