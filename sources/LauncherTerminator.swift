//
//  Terminator.swift
//  CPU See
//
//  Created by Piotr Zagawa on 01/08/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import Cocoa

class LauncherTerminator
{
    let bundleId = App.LAUNCHER_BUNDLE_ID
    let notificationName = Notification.Name(rawValue: App.NOTIFICATION_LAUNCHER_TERMINATE)

    func initialize()
    {
        //set termination observer
        let selector = #selector(OnTerminateNotification)
       
        DistributedNotificationCenter.default().addObserver(self, selector: selector, name: notificationName, object: bundleId, suspensionBehavior: .deliverImmediately)
    }
    
    func uninitialize()
    {
        //remove termination observer
        DistributedNotificationCenter.default().removeObserver(self, name: notificationName, object: bundleId)
    }
    
    @objc func OnTerminateNotification()
    {
        print("Notified to terminate: \(App.LAUNCHER_NAME)")
        NSApplication.shared.terminate(nil)
    }

    static func terminate()
    {
        print("Terminating: \(App.LAUNCHER_NAME)")
        NSApplication.shared.terminate(nil)
    }

    static func notifyToTerminate()
    {
        print("Notyfing launcher to terminate")
        
        let bundleId = App.LAUNCHER_BUNDLE_ID
        let notificationName = Notification.Name(rawValue: App.NOTIFICATION_LAUNCHER_TERMINATE)

        DistributedNotificationCenter.default().post(name: notificationName, object: bundleId)
    }

}
