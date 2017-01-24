//
//  AppDelegate.swift
//  gbsplayer
//
//  Created by Owner on 8/17/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // TODO: Use Autolayout
    // TODO: don't do this
    var gbsvc: GBSPlayerViewController? = nil
    
    @IBAction func openFile(_ sender: NSMenuItem) {
        let panel = NSOpenPanel()
        panel.begin { result in
            if result == NSFileHandlingPanelOKButton {
                if let gbsvc = self.gbsvc {
                    let url = panel.urls[0]
                    gbsvc.tryLoadingFile(at: url)
                }
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        //NSApplication.shared().delegate
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

