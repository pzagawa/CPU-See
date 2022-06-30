//
//  GCDTimer.swift
//  CPU See
//
//  Created by Piotr Zagawa on 23/08/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation

class GCDTimer
{
    private enum State
    {
        case suspended
        case resumed
    }

    let timeInterval: TimeInterval

    init(timeInterval: TimeInterval)
    {
        self.timeInterval = timeInterval
    }
    
    private lazy var timer: DispatchSourceTimer =
    {
        let timer = DispatchSource.makeTimerSource()
        
        timer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        
        timer.setEventHandler(handler:
        {   [weak self] in
            self?.eventHandler?()
        })
        
        return timer
    }()

    var eventHandler: (() -> Void)?
    
    var isEnabled: Bool
    {
        return state == State.resumed
    }
    
    private var state: State = .suspended

    deinit
    {
        timer.setEventHandler {}
        timer.cancel()
        resume()
        eventHandler = nil
    }

    func resume()
    {
        if state == .resumed
        {
            return
        }
        state = .resumed
        timer.resume()
    }

    func suspend()
    {
        if state == .suspended
        {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
