//
//  CpuInfoData.swift
//  CPU See
//
//  Created by Piotr Zagawa on 05/06/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation

public struct CpuInfoData
{
    //level index is value 0...LEVEL_INDEX_RANGE-1
    static let LEVEL_INDEX_RANGE: Double = 10.0

    private var system: Int = 0
    private var user: Int = 0
    private var idle: Int = 0
    
    let isValid: Bool
    
    init()
    {
        isValid = false
    }

    init(cpu_usage: System.CpuUsage)
    {
        system = Int(cpu_usage.system)
        user = Int(cpu_usage.user)
        idle = Int(cpu_usage.idle)

//MARK: TEST FIXED VALUES
//system = 30
//user = 50
//idle = 80
        
        isValid = cpu_usage.isValid
    }
    
    var levelIndexSystem: Int
    {
        get
        {
            return levelIndex(percent: system)
        }
    }

    var levelIndexUser: Int
    {
        get
        {
            return levelIndex(percent: user)
        }
    }

    var levelIndexIdle: Int
    {
        get
        {
            return levelIndex(percent: idle)
        }
    }
    
    func isEqual(info: inout CpuInfoData) -> Bool
    {
        return (system == info.system) && (user == info.user) && (idle == info.idle)
    }
    
    func isEqualLevelIndex(info: inout CpuInfoData) -> Bool
    {
        return (levelIndexSystem == info.levelIndexSystem) && (levelIndexUser == info.levelIndexUser) && (levelIndexIdle == info.levelIndexIdle)
    }
    
    private func levelIndex(percent: Int) -> Int
    {
        let index = Double(percent) / CpuInfoData.LEVEL_INDEX_RANGE

        return Int(index)
    }
    
    func toString() -> String
    {
        return "s:\(system), u:\(user), i:\(idle)"
    }
    
}
