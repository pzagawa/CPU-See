//
// System.swift
// SystemKit
//
// The MIT License
//
// Copyright (C) 2014-2017  beltex <https://github.com/beltex>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Darwin
import IOKit.pwr_mgt
import Foundation

//------------------------------------------------------------------------------
// MARK: PRIVATE PROPERTIES
//------------------------------------------------------------------------------

// As defined in <mach/tash_info.h>

private let HOST_BASIC_INFO_COUNT         : mach_msg_type_number_t = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_LOAD_INFO_COUNT          : mach_msg_type_number_t = UInt32(MemoryLayout<host_load_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_CPU_LOAD_INFO_COUNT      : mach_msg_type_number_t = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_VM_INFO64_COUNT          : mach_msg_type_number_t = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_SCHED_INFO_COUNT         : mach_msg_type_number_t = UInt32(MemoryLayout<host_sched_info_data_t>.size / MemoryLayout<integer_t>.size)
private let PROCESSOR_SET_LOAD_INFO_COUNT : mach_msg_type_number_t = UInt32(MemoryLayout<processor_set_load_info_data_t>.size / MemoryLayout<natural_t>.size)

public struct System
{
    //MARK: PUBLIC PROPERTIES
    
    //System page size. Shell cmd: pagesize, C func: getpagesize(), host_page_size()
    public static let PAGE_SIZE = vm_kernel_page_size
    
    public typealias CpuUsage = (system: Double, user: Double, idle: Double, nice: Double, isValid: Bool)

    //MARK: PUBLIC ENUMS

    public enum Unit : Double
    {
        case byte     = 1
        case kilobyte = 1024
        case megabyte = 1048576
        case gigabyte = 1073741824
    }
    
    //Options for loadAverage()
    public enum LOAD_AVG
    {
        /// 5, 30, 60 second samples
        case short
        /// 1, 5, 15 minute samples
        case long
    }
    
    //MARK: PRIVATE PROPERTIES
    
    fileprivate static let machHost = mach_host_self()
    fileprivate var loadPrevious = host_cpu_load_info()
    
    //MARK: PUBLIC INITIALIZERS
      
    public init()
    {
    }
    
    //MARK: PUBLIC METHODS

    //Get CPU usage (system, user, idle, nice). Delta between the current and last call. Thus, first call will always be inaccurate.
    public mutating func usageCPU() -> CpuUsage
    {
        let userDiff: Double
        let sysDiff: Double
        let idleDiff: Double
        let niceDiff: Double

        if let load = System.hostCPULoadInfo()
        {
            userDiff = Double(load.cpu_ticks.0 - loadPrevious.cpu_ticks.0)
            sysDiff  = Double(load.cpu_ticks.1 - loadPrevious.cpu_ticks.1)
            idleDiff = Double(load.cpu_ticks.2 - loadPrevious.cpu_ticks.2)
            niceDiff = Double(load.cpu_ticks.3 - loadPrevious.cpu_ticks.3)

            loadPrevious = load
        }
        else
        {
            userDiff = 0.0
            sysDiff  = 0.0
            idleDiff = 0.0
            niceDiff = 0.0
        }
                
        let totalTicks = sysDiff + userDiff + niceDiff + idleDiff

        let sys: Double
        let user: Double
        let idle: Double
        let nice: Double
        let isValid: Bool

        if (totalTicks == 0)
        {
            sys  = 0.0
            user = 0.0
            idle = 0.0
            nice = 0.0
            isValid = false
        }
        else
        {
            sys  = sysDiff  / totalTicks * 100.0
            user = userDiff / totalTicks * 100.0
            idle = idleDiff / totalTicks * 100.0
            nice = niceDiff / totalTicks * 100.0
            isValid = true
        }

        return (sys, user, idle, nice, isValid)
    }
    
    public mutating func cpuInfoData() -> CpuInfoData
    {
        let cpuUsage = usageCPU()

        return CpuInfoData(cpu_usage: cpuUsage)
    }
    
    //MARK: PUBLIC STATIC METHODS
    
    //Get the model name of this machine. Same as "sysctl hw.model"
    public static func modelName() -> String
    {
        let name: String
        
        var mib  = [CTL_HW, HW_MODEL]

        // Max model name size not defined by sysctl. Instead we use io_name_t via I/O Kit which can also get the model name
        var size = MemoryLayout<io_name_t>.size

        let ptr    = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        let result = sysctl(&mib, u_int(mib.count), ptr, &size, nil, 0)

        if result == 0
        {
            name = String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        else
        {
            name = String()
        }

        ptr.deallocate()

        #if DEBUG
            if result != 0
            {
                print("ERROR - \(#file):\(#function) - errno = \(result)")
            }
        #endif

        return name
    }

    //Number of physical cores on this machine.
    public static func physicalCores() -> Int
    {
        return Int(System.hostBasicInfo().physical_cpu)
    }
    
    //Number of logical cores on this machine. Will be equal to physicalCores() unless it has hyper-threading, in which case it will be double.
    public static func logicalCores() -> Int
    {
        return Int(System.hostBasicInfo().logical_cpu)
    }
      
    //System load average at 3 intervals. "Measures the average number of threads in the run queue." - via hostinfo manual page. https://en.wikipedia.org/wiki/Load_(computing)
    public static func loadAverage(_ type: LOAD_AVG = .long) -> [Double]
    {
        var avg = [Double](repeating: 0, count: 3)
        
        switch type
        {
            case .short:
                let result = System.hostLoadInfo().avenrun
                avg =
                [
                    Double(result.0) / Double(LOAD_SCALE),
                    Double(result.1) / Double(LOAD_SCALE),
                    Double(result.2) / Double(LOAD_SCALE)
                ]
            case .long:
                getloadavg(&avg, 3)
        }
        
        return avg
    }

    //Total number of processes & threads
    public static func processCounts() -> (processCount: Int, threadCount: Int)
    {
        let data = System.processorLoadInfo()
        return (Int(data.task_count), Int(data.thread_count))
    }
    
    //Size of physical memory on this machine
    public static func physicalMemory(_ unit: Unit = .gigabyte) -> Double
    {
        return Double(System.hostBasicInfo().max_mem) / unit.rawValue
    }
    
    //System memory usage (free, active, inactive, wired, compressed).
    public static func memoryUsage() -> (free       : Double,
                                         active     : Double,
                                         inactive   : Double,
                                         wired      : Double,
                                         compressed : Double)
    {
        let stats = System.VMStatistics64()
        
        let free     = Double(stats.free_count) * Double(PAGE_SIZE) / Unit.gigabyte.rawValue
        let active   = Double(stats.active_count) * Double(PAGE_SIZE) / Unit.gigabyte.rawValue
        let inactive = Double(stats.inactive_count) * Double(PAGE_SIZE) / Unit.gigabyte.rawValue
        let wired    = Double(stats.wire_count) * Double(PAGE_SIZE) / Unit.gigabyte.rawValue
        
        // Result of the compression. This is what you see in Activity Monitor
        let compressed = Double(stats.compressor_page_count) * Double(PAGE_SIZE) / Unit.gigabyte.rawValue
        
        return (free, active, inactive, wired, compressed)
    }
    
    //MARK: PRIVATE METHODS
    
    fileprivate static func hostBasicInfo() -> host_basic_info
    {
        // TODO: Why is host_basic_info.max_mem val different from sysctl?
        
        var size     = HOST_BASIC_INFO_COUNT
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size))
        {
            host_info(machHost, HOST_BASIC_INFO, $0, &size)
        }
  
        let data = hostInfo.move()
        hostInfo.deallocate()
        
        #if DEBUG
            if result != KERN_SUCCESS
            {
                print("ERROR - \(#file):\(#function) - kern_result_t = \(result)")
            }
        #endif
        
        return data
    }

    fileprivate static func hostLoadInfo() -> host_load_info
    {
        var size     = HOST_LOAD_INFO_COUNT
        let hostInfo = host_load_info_t.allocate(capacity: 1)
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size))
        {
            host_statistics(machHost, HOST_LOAD_INFO, $0, &size)
        }
        
        let data = hostInfo.move()
        hostInfo.deallocate()
        
        #if DEBUG
            if result != KERN_SUCCESS
            {
                print("ERROR - \(#file):\(#function) - kern_result_t \(result)")
            }
        #endif
        
        return data
    }
    
    fileprivate static func hostCPULoadInfo() -> host_cpu_load_info?
    {
        var size     = HOST_CPU_LOAD_INFO_COUNT
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size))
        {
            host_statistics(machHost, HOST_CPU_LOAD_INFO, $0, &size)
        }
        
        let data = hostInfo.move()
        hostInfo.deallocate()
        
        #if DEBUG
            if result != KERN_SUCCESS
            {
                print("ERROR - \(#file):\(#function) - kern_result_t = \(result)")
                return nil
            }
        #endif

        return data
    }
    
    fileprivate static func processorLoadInfo() -> processor_set_load_info
    {
        // NOTE: Duplicate load average and mach factor here
        
        var pset   = processor_set_name_t()
        var result = processor_set_default(machHost, &pset)
        
        if result != KERN_SUCCESS
        {
            #if DEBUG
                print("ERROR - \(#file):\(#function) - kern_result_t = \(result)")
            #endif

            return processor_set_load_info()
        }

        var count    = PROCESSOR_SET_LOAD_INFO_COUNT
        let info_out = processor_set_load_info_t.allocate(capacity: 1)
        
        result = info_out.withMemoryRebound(to: integer_t.self, capacity: Int(count))
        {
            processor_set_statistics(pset, PROCESSOR_SET_LOAD_INFO, $0, &count)
        }

        #if DEBUG
            if result != KERN_SUCCESS
            {
                print("ERROR - \(#file):\(#function) - kern_result_t \(result)")
            }
        #endif

        // This is isn't mandatory as I understand it, just helps keep the ref
        // count correct. This is because the port is to the default processor
        // set which should exist by default as long as the machine is running
        mach_port_deallocate(mach_task_self_, pset)

        let data = info_out.move()
        info_out.deallocate()
        
        return data
    }
    
    //64-bit virtual memory statistics. This should apply to all Mac's that run 10.9 and above. Swift runs on 10.9 and above, and 10.9 is x86_64 only.
    fileprivate static func VMStatistics64() -> vm_statistics64
    {
        var size     = HOST_VM_INFO64_COUNT
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size))
        {
            host_statistics64(machHost, HOST_VM_INFO64, $0, &size)
        }

        let data = hostInfo.move()
        hostInfo.deallocate()
        
        #if DEBUG
            if result != KERN_SUCCESS
            {
                print("ERROR - \(#file):\(#function) - kern_result_t = \(result)")
            }
        #endif

        return data
    }
}
