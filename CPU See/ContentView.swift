//
//  ContentView.swift
//  CPU See
//
//  Created by Piotr Zagawa on 30/05/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import SwiftUI

struct ContentView: View
{
    var body: some View
    {
        Text("TEST").frame(maxWidth: 200, maxHeight: 64).foregroundColor(Color.init(red: 1, green: 0.5, blue: 0))
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView()
    }
}
