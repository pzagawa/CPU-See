//
//  App.swift
//  CPU See
//
//  Created by Piotr Zagawa on 05/07/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import Cocoa

class App
{
    static let APP_NAME = "CPU See"
    static let LAUNCHER_NAME = "CPU See Launcher"

    static let APP_BUNDLE_ID = "com.pzagawa.CPU-See"
    static let LAUNCHER_BUNDLE_ID = "com.pzagawa.CPU-See.Launcher"

    static let NOTIFICATION_LAUNCHER_TERMINATE = "NOTIFICATION_CPU-SEE_LAUNCHER_TERMINATE"
    
    static var appInfoText: String
    {
        let locale = NSLocale.current.identifier

        return "\(APP_NAME). Version \(shortVersionString) build \(buildRevisionString). Locale: \(locale); OS \(sysVersion)"
    }

    static var shortVersionString: String
    {
        if let infoData: [String: Any?] = Bundle.main.infoDictionary
        {
            if let value: Any? = infoData["CFBundleShortVersionString"]
            {
                if value is String
                {
                    return value as! String
                }
            }
        }
        
        return "<unknown appShortVersionString>"
    }

    static var buildRevisionString:String
    {
        if let infoData: [String: Any?] = Bundle.main.infoDictionary
        {
            if let value: Any? = infoData["CFBundleVersion"]
            {
                if value is String
                {
                    return value as! String
                }
            }
        }
        
        return "<unknown appBuildRevisionString>"
    }

    static var sysVersion: String
    {
        let version: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    static func ShowError(title: String, text: String)
    {
        let alert = NSAlert()
        alert.messageText = "\(title): error"
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    static var activityMonitorAppUrl: URL?
    {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor")
    }
    
    static func runApp(url: URL)
    {
        let configuration = NSWorkspace.OpenConfiguration()
    
        NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }

}
