//
//  ContentView.swift
//  Spendings
//
//  Created by Hung Dao on 6/12/24.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Budgets", systemImage: "dongsign.gauge.chart.lefthalf.righthalf") {
                NavigationStack {
                    BudgetsView(
                        store: Store(initialState: Budgets.State()) {
                            Budgets()
                        }
                    )
                }
            }
            Tab("All spendings", systemImage: "dongsign.bank.building.fill") {
                Text("Tab 2")
            }
        }
    }
}

#Preview {
    ContentView()
}
