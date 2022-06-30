//
//  AppDelegate.swift
//  CPU See Launcher
//
//  Created by Piotr Zagawa on 22/07/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    let terminator: LauncherTerminator = LauncherTerminator()
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        print("Launcher starting..")
        
        //exit if main app is running
        if Autostart.isMainAppRunning
        {
            LauncherTerminator.terminate()
        }

        //wait for main app notification
        terminator.initialize()

        //start main app
        if (Autostart.startMainApp() == false)
        {
            LauncherTerminator.terminate()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool
    {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply
    {
        return NSApplication.TerminateReply.terminateNow;
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        print("Launcher ending..")
        
        terminator.uninitialize()
    }

}
