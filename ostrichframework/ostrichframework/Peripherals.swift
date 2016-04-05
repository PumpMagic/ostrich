//
//  Peripherals.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/4/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


public typealias Address = UInt16


protocol HandlesReads {
    func read(addr: Address) -> UInt8
}
protocol HandlesWrites {
    func write(val: UInt8, to addr: Address)
}