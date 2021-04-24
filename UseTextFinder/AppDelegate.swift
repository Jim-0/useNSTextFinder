//
//  AppDelegate.swift
//  UseTextFinder
//
//  Created by jim on 2021/4/24.
//  Copyright © 2021 Jim. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminate(_ sender: NSApplication)-> NSApplication.TerminateReply {
        return .terminateNow
    }


}

