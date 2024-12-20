//
//  ContentView.swift
//  Spendings
//
//  Created by Hung Dao on 6/12/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Root {
    @ObservableState
    struct State: Equatable {
        @Shared var budgets: [Budget]
        
        init(budgets: [Budget] = []) {
            self._budgets = Shared(value: budgets)
        }
    }

    enum Action {
        case loadBudgets
        case budgetsResponse(Result<[Budget], any Error>)
    }

    @Dependency(\.budgetClient) var client
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadBudgets:
                return .run { send in
                    await send(.budgetsResponse(Result {try await self.client.fetch()}))
                }
            case let .budgetsResponse(.success(response)):
                state.$budgets.withLock { $0 = response}
                return .none
            case .budgetsResponse(.failure):
                state.$budgets.withLock { $0 = []}
                return .none
            }
        }
    }
}

struct RootView: View {
    @Bindable var store: StoreOf<Root>

    var body: some View {
        if !store.budgets.isEmpty {
            TabView {
                Tab("Budgets", systemImage: "dongsign.gauge.chart.lefthalf.righthalf") {
                    NavigationStack {
                        BudgetsView(
                            store: Store(initialState: Budgets.State(budgets: store.$budgets)) {
                                Budgets()
                            }
                        )
                    }
                }
                Tab("Accounts", systemImage: "wallet.bifold.fill") {
                    NavigationStack {
                        AccountsView(
                            store:
                                Store(initialState: Accounts.State()) {
                            Accounts()
                        })
                    }
                }
                Tab("Add transaction", systemImage: "plus.circle") {
                    AddTransactionView(store: Store(initialState: AddTransaction.State(budgets: store.$budgets)) {
                        AddTransaction()
                    })
                }
            }
        } else {
            ProgressView()
                .onAppear {
                    store.send(.loadBudgets)
                }
        }
        
    }
}

#Preview {
    RootView(store: Store(initialState: Root.State(), reducer: {
        Root()
    }))
}
