//
//  StatusImage.swift
//  CPU See
//
//  Created by Piotr Zagawa on 03/06/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import Cocoa
import CoreFoundation
import SwiftUI

public class StatusImage
{
    let H_MARGIN: CGFloat = 4.0
    let H_SPACE: CGFloat = 2.0
    let ICON_LEFT: CGFloat = 2.0
    let ITEM_HEIGHT: CGFloat = 18.0
    let ICON_WIDTH: CGFloat = 18
    let METER_WIDTH: CGFloat = 43.0
    let ITEM_WIDTH: CGFloat
    let ITEM_SIZE: NSSize
    let METER_LEFT: CGFloat
    let METER_ITEM_WIDTH: CGFloat = 3.0
    let METER_ITEM_SPACE: CGFloat = 1.0

    typealias RenderUpdater = () -> Void

    private var sys = System()
    
    private var updateTimer: GCDTimer?
    private let updateQueue: OperationQueue
    private var updateInterval: Double = 0.1
    
    private var isDarkMode: Bool = false
    
    var theme: Theme!
    var cpuInfoData: CpuInfoData = CpuInfoData()
    let valueIdle: AnimValue = AnimValue()
    let valueUser: AnimValue = AnimValue()
    let valueSystem: AnimValue = AnimValue()
    
    private var isResetState: Bool = false

    init()
    {
        self.updateQueue = OperationQueue.init()
        self.updateQueue.maxConcurrentOperationCount = 1;
        self.updateQueue.underlyingQueue = DispatchQueue.global()

        ITEM_WIDTH = H_SPACE + ICON_WIDTH + H_SPACE + METER_WIDTH + H_SPACE
        ITEM_SIZE = NSSize(width: ITEM_WIDTH, height: ITEM_HEIGHT)
        METER_LEFT = H_SPACE + ICON_WIDTH + H_SPACE
        
        theme = Theme()
    }

    var renderUpdater: RenderUpdater? = nil
    
    var itemWidh: CGFloat
    {
        return ITEM_WIDTH
    }
    
    var animationInactive: Bool
    {
        return valueIdle.equalTarget && valueUser.equalTarget && valueSystem.equalTarget
    }

    var isUpdateEnabled: Bool
    {
        if (isResetState)
        {
            if (animationInactive)
            {
                isResetState = false
            }

            return false
        }
        else
        {
            return true
        }
    }

    private func updateDarkMode()
    {
        isDarkMode = false
        
        if let appearance: NSAppearance.Name = NSAppearance.current.bestMatch(from: [.aqua, .darkAqua])
        {
            if appearance == NSAppearance.Name.darkAqua
            {
                isDarkMode = true;
            }
        }
    }
    
    var isUpdateTimerEnabled: Bool
    {
        if let timer = self.updateTimer
        {
            return timer.isEnabled
        }
        else
        {
            return false
        }
    }

    func enableUpdateTimer()
    {
        self.disableUpdateTimer()
        
        self.updateTimer = GCDTimer(timeInterval: updateInterval)

        if let timer = self.updateTimer
        {
            timer.eventHandler =
            {
                [weak self] in
                
                self?.OnTimerUpdate()
            }

            timer.resume()
        }
    }
    
    func disableUpdateTimer()
    {
        if let timer = self.updateTimer
        {
            if timer.isEnabled
            {
                timer.suspend()
            }
            
            self.updateTimer = nil
        }
    }

    private func OnTimerUpdate()
    {
        if (self.isUpdateTimerEnabled == false)
        {
            return
        }

        if let updater = renderUpdater
        {
            updater()
            
            update()
        }
    }

    func reset()
    {
        valueIdle.value = Int(CpuInfoData.LEVEL_INDEX_RANGE)
        valueUser.value = Int(CpuInfoData.LEVEL_INDEX_RANGE)
        valueSystem.value = Int(CpuInfoData.LEVEL_INDEX_RANGE)
        
        isResetState = true
    }
        
    func setCpuInfoData(cpu_info_data: CpuInfoData)
    {
        if (cpu_info_data.isEqualLevelIndex(info: &cpuInfoData))
        {
            return
        }
        
        cpuInfoData = cpu_info_data
        
        valueIdle.value = cpu_info_data.levelIndexIdle
        valueUser.value = cpu_info_data.levelIndexUser
        valueSystem.value = cpu_info_data.levelIndexSystem
    }

    func renderImage() -> NSImage
    {
        let new_image = NSImage.init(size: ITEM_SIZE, flipped: false)
        {
            [weak self, theme] (rect: NSRect) -> Bool in

            guard let this = self else
            {
                return false
            }

            guard let context = NSGraphicsContext.current?.cgContext else
            {
                return false
            }

            this.updateDarkMode()

            let rect_icon = NSRect.init(x: this.ICON_LEFT, y: 0.0, width: this.ICON_WIDTH, height: this.ITEM_HEIGHT)
            let rect_meter = NSRect.init(x: this.METER_LEFT, y: 0.0, width: this.METER_WIDTH, height: this.ITEM_HEIGHT)
            let rect_meter_bkg = rect_meter.insetBy(dx: 2.0, dy: 2.0)

            //status item icon
            if let theme_ref = theme
            {
                theme_ref.systemMenuIcon.draw(in: rect_icon)
            }
        
            //meter background
            this.drawMeterBackground(context: context, rect: rect_meter)
        
            //meter bars
            this.drawMeterBarIdle(context: context, rect: rect_meter_bkg)
            this.drawMeterBarUser(context: context, rect: rect_meter_bkg)
            this.drawMeterBarSystem(context: context, rect: rect_meter_bkg)
            
            return true;
        }
        
        return new_image;
    }

    private func update()
    {
        valueIdle.tick()
        valueUser.tick()
        valueSystem.tick()
    }
    
    private func drawMeterBackground(context: CGContext, rect: NSRect)
    {
        var bkg_rect = rect

        context.setFillColor(theme.frameColor)
        
        bkg_rect.fill()

        context.setFillColor(theme.bkgColor)

        bkg_rect = bkg_rect.insetBy(dx: 1.0, dy: 1.0)
        bkg_rect.fill()
    }

    private func drawMeterBarIdle(context: CGContext, rect: NSRect)
    {
        var rect_meter = rect
        rect_meter.origin.y = 2
        rect_meter.size.height = 2.0
        
        drawMeterBar(context: context, rect: rect_meter, color: theme.colorIdle, level_index: valueIdle.value)
    }
    
    private func drawMeterBarUser(context: CGContext, rect: NSRect)
    {
        var rect_meter = rect
        rect_meter.origin.y = 5
        rect_meter.size.height = 5.0

        drawMeterBar(context: context, rect: rect_meter, color: theme.colorUser, level_index: valueUser.value)
    }

    private func drawMeterBarSystem(context: CGContext, rect: NSRect)
    {
        var rect_meter = rect
        rect_meter.origin.y = 11
        rect_meter.size.height = 5.0
        
        drawMeterBar(context: context, rect: rect_meter, color: theme.colorSystem, level_index: valueSystem.value)
    }

    private func drawMeterBar(context: CGContext, rect: NSRect, color: CGColor, level_index: Int)
    {
        let BAR_MAX_ITEMS: Int = Int(CpuInfoData.LEVEL_INDEX_RANGE)
        
        let ITEM_STEP = METER_ITEM_WIDTH + METER_ITEM_SPACE
        
        var color_r: CGFloat = 1.0
        var color_g: CGFloat = 1.0
        var color_b: CGFloat = 1.0

        if let colors = color.components
        {
            color_r = colors[0]
            color_g = colors[1]
            color_b = colors[2]
        }

        var left = rect.origin.x + rect.size.width
        left = left - METER_ITEM_WIDTH

        for index in 1...BAR_MAX_ITEMS
        {
            var color_alpha: CGFloat = 1.0
            
            if (index > level_index)
            {
                color_alpha = theme.meterBarAlpha(dark_mode: isDarkMode)
            }
            
            let item_color = CGColor.init(red: color_r, green: color_g, blue: color_b, alpha: color_alpha)

            context.setFillColor(item_color)

            let item_rect = NSRect.init(x: left, y: rect.origin.y, width: METER_ITEM_WIDTH, height: rect.height)

            item_rect.fill()

            left = left - ITEM_STEP
        }
    }
    
}
