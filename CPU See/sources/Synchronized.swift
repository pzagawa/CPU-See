//
//  Synchronized.swift
//  CPU See
//
//  Created by Piotr Zagawa on 31/05/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation

public func synchronized<T>(_ lock: AnyObject, closure: () -> T) -> T
{
    defer
    {
        objc_sync_exit(lock)
    }

    var result: T? = nil

    objc_sync_enter(lock)
    
    result = closure()
    
    return result!
}
