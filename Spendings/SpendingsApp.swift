//
//  SpendingsApp.swift
//  Spendings
//
//  Created by Hung Dao on 6/12/24.
//

import ComposableArchitecture
import SwiftUI

@main
struct SpendingsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(store: Store(initialState: Root.State(budgets: [])) {
                Root()
            })
        }
    }
}
