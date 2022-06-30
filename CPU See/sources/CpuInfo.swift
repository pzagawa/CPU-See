//
//  CpuInfo.swift
//  CPU See
//
//  Created by Piotr Zagawa on 31/05/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation

public class CpuInfo
{
    private var sys = System()

    private var updateTimer: GCDTimer?
    private let updateQueue: OperationQueue
    private var updateInterval: Double = 0.1
    
    private var cpuInfoData: CpuInfoData = CpuInfoData()

    init()
    {
        self.updateQueue = OperationQueue.init()
        self.updateQueue.maxConcurrentOperationCount = 1;
        self.updateQueue.underlyingQueue = DispatchQueue.global()

        print("CpuInfo: \(System.modelName()). CPU cores: \(System.physicalCores()) / \(System.logicalCores()).")
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
        print("CpuInfo: update timer started")
        
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

            print("CpuInfo: update timer disabled")
        }
    }

    private func updateOnTimer()
    {
        if (self.isUpdateTimerEnabled == false)
        {
            print("CpuInfo: update timer disabled")
            
            return
        }

        synchronized(self)
        {
            [weak self] in
            
            if let this = self
            {
                cpuInfoData = this.sys.cpuInfoData()
            }
        }
    }
    
    private func OnTimerUpdate()
    {
        if (self.isUpdateTimerEnabled == false)
        {
            print("CpuInfo: update timer disabled")

            return
        }

        synchronized(self)
        {
            [weak self] in
            
            if let this = self
            {
                cpuInfoData = this.sys.cpuInfoData()
            }
        }
    }
    
    func getCpuInfoData() -> CpuInfoData
    {
        synchronized(self)
        {
            [weak self] in
            
            if let this = self
            {
                return this.cpuInfoData
            }
            else
            {
                print("CpuInfo: getCpuInfoData return empty")
                
                return CpuInfoData()
            }
        }
    }

}
