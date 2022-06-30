//
//  AppDelegate.swift
//  CPU See
//
//  Created by Piotr Zagawa on 30/05/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Cocoa
import CoreFoundation
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    private var statusItem: NSStatusItem? = nil;
    
    var window: NSWindow!

    var statusImage: StatusImage!
    var cpuInfo: CpuInfo!
    
    weak var menuThemeRef: NSMenu?
    weak var menuStartRef: NSMenu?
    
    func applicationWillFinishLaunching(_ notification: Notification)
    {
        print("Initializing \(App.appInfoText)")
    }

    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        print("Starting CPU See..")

        cpuInfo = CpuInfo()
        statusImage = StatusImage()

        initialize()

        //manage launcher
        print("Closing launcher..")

        if (Autostart.isLauncherRunning)
        {
            LauncherTerminator.notifyToTerminate()
        }

        print("Initialized.")
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
        print("Stopping CPU See..")

        uninitialize()
    }
        
    func initialize()
    {
        print("Initializing..")

        showStatusItem()
        
        reset()
        
        statusImage.renderUpdater =
        {
            [weak self] in
            
            if let this = self
            {
                this.renderUpdate()
            }
        }
        
        statusImage.enableUpdateTimer()
        cpuInfo.enableUpdateTimer()
    }

    func uninitialize()
    {
        print("Uninitializing..")

        cpuInfo.disableUpdateTimer()
        statusImage.disableUpdateTimer()

        statusImage.renderUpdater = nil
        
        hideStatusItem()
    }
    
    func reset()
    {
        statusImage.reset()

        let image = statusImage.renderImage()

        setButtonImage(image: image)
    }
    
    func renderUpdate()
    {
        let data: CpuInfoData = cpuInfo.getCpuInfoData()
        
        if (data.isValid)
        {
            if statusImage.isUpdateEnabled
            {
                statusImage.setCpuInfoData(cpu_info_data: data)
            }
        }

        if (statusImage.animationInactive == false)
        {
            updateImage()
        }
    }
    
    func updateImage()
    {
        DispatchQueue.main.async
        {
            [weak self ] in
            
            if let this = self
            {
                let image = this.statusImage.renderImage()

                this.setButtonImage(image: image)
            }
        }
    }
    
    func showStatusItem()
    {
        if statusItem == nil
        {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

            print("Status bar height: \(NSStatusBar.system.thickness)")

            if let status_item = statusItem
            {
                status_item.menu = createStatusBarMenu()
                status_item.length = statusImage.itemWidh
            }
        }
    }
    
    func hideStatusItem()
    {
        if let status_item = statusItem
        {
            NSStatusBar.system.removeStatusItem(status_item)
            statusItem = nil
        }
    }
    
    func setButtonImage(image: NSImage)
    {
        if let status_item = statusItem
        {
            if let button = status_item.button
            {
                button.image = image
            }
        }
 
    }
    
    @objc func OnMenuItemTheme(sender: NSMenuItem)
    {
        let theme_name = sender.title
        
        if let theme = Theme.Name.init(rawValue: theme_name)
        {
            statusImage.theme.theme_name = theme
            statusImage.theme.saveTheme()

            if let theme_menu = menuThemeRef
            {
                let current_theme_name = statusImage.theme.theme_name

                Theme.updateMenu(theme_menu: theme_menu, current_theme_name: current_theme_name.rawValue)
                
                updateImage()
            }
        }
    }
    
    @objc func OnMenuItemStartAtLogin(sender: NSMenuItem)
    {
        let is_start_at_login = sender.tag == 1 ? true : false

        print("Selected start at login: \(is_start_at_login)")
        
        Autostart.startLauncherAtLogin = is_start_at_login

        if let start_menu = menuStartRef
        {
            Autostart.updateMenu(start_menu: start_menu)
        }
    }

    @objc func OnMenuItemRunActivityMonitor(sender: NSMenuItem)
    {
        if let app_url = App.activityMonitorAppUrl
        {
            App.runApp(url: app_url)
        }
    }

    @objc func OnMenuItemQuitApp(sender: NSMenuItem)
    {
        print("Quitting: \(App.APP_NAME)")
        NSApplication.shared.terminate(nil)
    }
    
    func createStatusBarMenu() -> NSMenu
    {
        let theme_selector = #selector(OnMenuItemTheme)
        let start_selector = #selector(OnMenuItemStartAtLogin)
        let quit_selector = #selector(OnMenuItemQuitApp)

        let current_theme_name = statusImage.theme.theme_name
        
        let menu = NSMenu()

        //add activity monitor menu item
        var activity_monitor_selector: Selector? = nil

        if App.activityMonitorAppUrl != nil
        {
            activity_monitor_selector = #selector(OnMenuItemRunActivityMonitor)
        }

        let activity_monitor_menu_item = NSMenuItem(title: "Activity monitor", action: activity_monitor_selector, keyEquivalent: "a")
        menu.addItem(activity_monitor_menu_item)
        
        //add theme menu item
        menu.addItem(NSMenuItem.separator())

        let theme_menu = Theme.createMenu(selector: theme_selector, current_theme_name: current_theme_name.rawValue)
        menu.addItem(theme_menu)
        
        menuThemeRef = theme_menu.submenu
        
        //add start menu item
        let start_menu = Autostart.createMenu(selector: start_selector)
        menu.addItem(start_menu)
        menuStartRef = start_menu.submenu

        //add quit menu item
        menu.addItem(NSMenuItem.separator())

        let quit_menu_item = NSMenuItem(title: "Quit CPU See", action: quit_selector, keyEquivalent: "q")
        menu.addItem(quit_menu_item)

        return menu
    }

}
