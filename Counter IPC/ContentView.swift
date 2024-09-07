//
//  ContentView.swift
//  Counter IPC
//
//  Created by Seth Corker on 07/09/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var counter = CounterModel()
    var body: some View {
        VStack {
            Text("\(counter.value)")
            HStack {
                Button("Increment", action: counter.increment)
                Button("Decrement", action: counter.decrement)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
