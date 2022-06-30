//
//  Theme.swift
//  CPU See
//
//  Created by Piotr Zagawa on 06/06/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import Cocoa
import CoreFoundation

struct Theme
{
    //case names equals assets names in resources
    enum Name: String, CaseIterable
    {
        case system
        case color1
        case color2
        case gray
        case green
        case orange
        case blue
    }

    //case names equals assets names in resources
    enum MenuBarIcon: String, CaseIterable
    {
        case system
        case color1
        case gray
        case orange
        case blue
    }

    static let DEFAULT_THEME_NAME = Name.orange
    
    var theme_name: Name = DEFAULT_THEME_NAME
    
    private var menuBarIcons: [MenuBarIcon: NSImage] = [:]
    
    init()
    {
        loadTheme()
        loadMenuBarIcons()
    }
    
    public func saveTheme()
    {
        print("Theme: saving \(theme_name)")
        
        Settings.instance.themeName = theme_name.rawValue
    }
    
    public mutating func loadTheme()
    {
        if let name = Settings.instance.themeName
        {
            if let theme = Name.init(rawValue: name)
            {
                print("Theme: loading \(theme)")
                
                theme_name = theme
                return
            }
        }

        print("Theme: default set")

        //default theme name
        theme_name = Theme.DEFAULT_THEME_NAME
    }
    
    private mutating func loadMenuBarIcons()
    {
        for icon_name_item in MenuBarIcon.allCases
        {
            let icon_name = icon_name_item.rawValue
            let icon = NSImage(named: "menubar-icon-\(icon_name)")
            menuBarIcons[icon_name_item] = icon
        }
    }
    
    private func menuBarIcon(menu_bar_icon: MenuBarIcon) -> NSImage?
    {
        return menuBarIcons[menu_bar_icon]
    }
    
    private func colorName(suffix: String) -> NSColor.Name
    {
        return NSColor.Name("\(theme_name.rawValue)-\(suffix)")
    }
    
    private func nscolor(name: String) -> CGColor
    {
        return NSColor(named: colorName(suffix: name))!.cgColor
    }
    
    func meterBarAlpha(dark_mode: Bool) -> CGFloat
    {
        if (theme_name == Name.system)
        {
            return dark_mode ? 0.1 : 0.1
        }
        
        return dark_mode ? 0.1 : 0.2
    }

    var systemMenuIcon: NSImage
    {
        if (theme_name == Name.system)
        {
            return menuBarIcon(menu_bar_icon: MenuBarIcon.system)!
        }

        if (theme_name == Name.gray)
        {
            return menuBarIcon(menu_bar_icon: MenuBarIcon.gray)!
        }

        if (theme_name == Name.orange)
        {
            return menuBarIcon(menu_bar_icon: MenuBarIcon.orange)!
        }

        if (theme_name == Name.blue)
        {
            return menuBarIcon(menu_bar_icon: MenuBarIcon.blue)!
        }

        return menuBarIcon(menu_bar_icon: MenuBarIcon.color1)!
    }
    
    var frameColor: CGColor
    {
        return nscolor(name: "frame")
    }

    var bkgColor: CGColor
    {
        return nscolor(name: "bkg")
    }
    
    var colorIdle: CGColor
    {
        return nscolor(name: "bar-idle")
    }

    var colorUser: CGColor
    {
        return nscolor(name: "bar-user")
    }

    var colorSystem: CGColor
    {
        return nscolor(name: "bar-system")
    }

    static func createMenu(selector: Selector, current_theme_name: String) -> NSMenuItem
    {
        let theme_menu = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
                
        theme_menu.submenu = NSMenu()

        for theme_item in Theme.Name.allCases
        {
            let item_name = theme_item.rawValue
            let menu_item = NSMenuItem(title: item_name, action: selector, keyEquivalent: "")
            
            if (current_theme_name == item_name)
            {
                menu_item.state = NSControl.StateValue.on
            }
            else
            {
                menu_item.state = NSControl.StateValue.off
            }
            
            theme_menu.submenu?.addItem(menu_item)
        }
        
        return theme_menu
    }

    static func updateMenu(theme_menu: NSMenu, current_theme_name: String)
    {
        for menu_item in theme_menu.items
        {
            let item_name = menu_item.title

            if (current_theme_name == item_name)
            {
                menu_item.state = NSControl.StateValue.on
            }
            else
            {
                menu_item.state = NSControl.StateValue.off
            }
        }
    }

}
