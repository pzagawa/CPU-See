//
//  AnimValue.swift
//  CPU See
//
//  Created by Piotr Zagawa on 07/06/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation

public class AnimValue
{
    let INC_SPEED: Double = 4.0
    let DEC_SPEED: Double = 1.0
    var currentValue: Double = 0.0
    var targetValue: Double = 0.0
    
    var value: Int
    {
        set
        {
            targetValue = Double(newValue)
        }
        get
        {
            return Int(currentValue)
        }
    }

    private func incValue()
    {
        currentValue = currentValue + INC_SPEED
        
        if (currentValue >= targetValue)
        {
            currentValue = targetValue
        }
    }
    
    private func decValue()
    {
        currentValue = currentValue - DEC_SPEED

        if (currentValue <= targetValue)
        {
            currentValue = targetValue
        }
    }
    
    var equalTarget: Bool
    {
        return (currentValue == targetValue)
    }

    var lessThanTarget: Bool
    {
        return (currentValue < targetValue)
    }

    var moreThanTarget: Bool
    {
        return (currentValue > targetValue)
    }

    func tick()
    {
        if equalTarget
        {
            return
        }
        
        if lessThanTarget
        {
            incValue()
            return
        }
        
        if moreThanTarget
        {
            decValue()
            return
        }
    }
    
    func toString() -> String
    {
        return "current: \(currentValue), target: \(targetValue)"
    }
    
}
