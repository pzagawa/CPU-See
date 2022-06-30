//
//  Launcher.swift
//  CPU See Launcher
//
//  Created by Piotr Zagawa on 29/07/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import Cocoa
import ServiceManagement

class Autostart
{

static var isLauncherRunning: Bool
{
    get
    {
        let list = NSWorkspace.shared.runningApplications
        
        for application in list
        {
            if (application.bundleIdentifier == App.LAUNCHER_BUNDLE_ID)
            {
                return true
            }
        }
        
        return false
    }
}
    
static var isMainAppRunning: Bool
{
    get
    {
        let list = NSWorkspace.shared.runningApplications
        
        for application in list
        {
            if (application.bundleIdentifier == App.APP_BUNDLE_ID)
            {
                return true
            }
        }
        
        return false
    }
}

static var startLauncherAtLogin: Bool
{
    set
    {
        print("Autostart: startLauncherAtLogin: \(newValue)")

        let bundleId: CFString = App.LAUNCHER_BUNDLE_ID as NSString

        if SMLoginItemSetEnabled(bundleId, newValue)
        {
            print("- value set")

            Settings.instance.startAtLogin = newValue
        }
        else
        {
            let text_add = "Can't add \(App.LAUNCHER_NAME) to login item list"
            let text_rem = "Can't remove \(App.LAUNCHER_NAME) from login item list"
            
            let text = newValue ? text_add : text_rem

            App.ShowError(title: App.LAUNCHER_NAME, text: text)
        }
    }
    get
    {
        return Settings.instance.startAtLogin
    }
}

static func removeTextItem(lastItem: String, items: inout [String]) -> Bool
{
    if let item = items.last
    {
        if item.caseInsensitiveCompare(lastItem) == ComparisonResult.orderedSame
        {
            items.removeLast()
            return true
        }
        else
        {
            print("removeTextItem: \(lastItem) not found")
        }
    }

    return false
}

//
//launcher bundle path:
//[APP].app/Contents/Library/LoginItems/[LAUNCHER].app
//
static var mainAppBundlePath: String?
{
    get
    {
        let path = Bundle.main.bundleURL
        var pathComponents: [String] = path.pathComponents

        if removeTextItem(lastItem: "\(App.LAUNCHER_NAME).app", items: &pathComponents)
        {
            if removeTextItem(lastItem: "LoginItems", items: &pathComponents)
            {
                if removeTextItem(lastItem: "Library", items: &pathComponents)
                {
                    if removeTextItem(lastItem: "Contents", items: &pathComponents)
                    {
                        return NSString.path(withComponents: pathComponents)
                    }
                }
            }
        }

        print("mainAppBundlePath: launcher path invalid: \(path)")
        return nil
    }
}

static func startMainApp() -> Bool
{
    print("Starting main app: \(App.APP_NAME)")

    //get main app path
    if let mainAppPath = mainAppBundlePath
    {
        if (NSWorkspace.shared.launchApplication(mainAppPath))
        {
            print("- app started")
            
            return true;
        }
        else
        {
            print("- error: can't start main app")

            App.ShowError(title: App.LAUNCHER_NAME, text: "Can't start main app: \(mainAppPath)")
        }
    }
    else
    {
        print("- error: can't find main app")
        
        App.ShowError(title: App.LAUNCHER_NAME, text: "Can't find main app: \(App.APP_NAME)")
    }
    
    return false
}

static func createMenu(selector: Selector) -> NSMenuItem
{
    let is_start_at_login_enabled = startLauncherAtLogin

    print("Create start menu: start at login: \(is_start_at_login_enabled)")

    let start_menu = NSMenuItem(title: "Start at login", action: nil, keyEquivalent: "")
            
    start_menu.submenu = NSMenu()

    //enabled menu item
    let enabled_menu_item = NSMenuItem(title: "enabled", action: selector, keyEquivalent: "")

    enabled_menu_item.tag = 1
    enabled_menu_item.state = is_start_at_login_enabled == true ? NSControl.StateValue.on : NSControl.StateValue.off
    start_menu.submenu?.addItem(enabled_menu_item)
    
    //disabled menu item
    let disabled_menu_item = NSMenuItem(title: "disabled", action: selector, keyEquivalent: "")

    disabled_menu_item.tag = 0
    disabled_menu_item.state = is_start_at_login_enabled == false ? NSControl.StateValue.on : NSControl.StateValue.off
    start_menu.submenu?.addItem(disabled_menu_item)
    
    return start_menu
}

static func updateMenu(start_menu: NSMenu)
{
    let is_start_at_login_enabled = startLauncherAtLogin

    for menu_item in start_menu.items
    {
        //disabled menu item
        if (menu_item.tag == 0)
        {
            menu_item.state = is_start_at_login_enabled == false ? NSControl.StateValue.on : NSControl.StateValue.off
        }

        //enabled menu item
        if (menu_item.tag == 1)
        {
            menu_item.state = is_start_at_login_enabled == true ? NSControl.StateValue.on : NSControl.StateValue.off
        }
    }
}

}
