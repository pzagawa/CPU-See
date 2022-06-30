//
//  Settings.swift
//  CPU See
//
//  Created by Piotr Zagawa on 05/07/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation

public class Settings
{
    static let instance = Settings()
    
    static let PREFIX = App.APP_BUNDLE_ID
    
    private let KEY_THEME_NAME: String = "\(PREFIX).KEY_THEME_NAME"
    private let KEY_START_AT_LOGIN: String = "\(PREFIX).KEY_START_AT_LOGIN"

    var startAtLogin: Bool
    {
        set
        {
            UserDefaults.standard.set(newValue, forKey: KEY_START_AT_LOGIN)
            UserDefaults.standard.synchronize()
        }
        get
        {
            return UserDefaults.standard.bool(forKey: KEY_START_AT_LOGIN)
        }
    }
     
    var themeName: String?
    {
        set
        {
            UserDefaults.standard.set(newValue, forKey: KEY_THEME_NAME)
            UserDefaults.standard.synchronize()
        }
        get
        {
            return UserDefaults.standard.string(forKey: KEY_THEME_NAME)
        }
    }
    
}
