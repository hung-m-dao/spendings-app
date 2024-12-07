//
//  Budgets.swift
//  Spendings
//
//  Created by Hung Dao on 7/12/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Budgets {
    @ObservableState
    struct State: Equatable {
        var budgets: [Budget]?
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
                state.budgets = response
                return .none
            case .budgetsResponse(.failure):
                state.budgets = []
                return .none
            }
        }
    }
}

struct BudgetsView: View {
    @Bindable var store: StoreOf<Budgets>

    var body: some View {
        
        if let budgets = store.budgets {
            List {
                ForEach(budgets) { budget in
                    NavigationLink(destination: {
                        TransactionsView(store: Store(initialState: Transactions.State(budgetID: budget.id)) {
                            Transactions()
                        })
                        .navigationTitle(budget.name)
                    }, label: {
                        VStack(alignment: .leading) {
                            Text("\(budget.name)")
                            if budget.spentRatio > 1 {
                                ProgressView(value: 1) {
                                    Text("\(budget.descriptionText)")
                                }
                                .tint(.red)
                            } else {
                                ProgressView(value: budget.spentRatio) {
                                    Text("\(budget.descriptionText)")
                                }
                            }
                        }
                    })
                    
                }
            }
            .refreshable {
                store.send(.loadBudgets)
            }
        } else {
            ProgressView()
                .onAppear {
                    store.send(.loadBudgets)
                }
        }
    }
}

private extension Budget {
    var spentRatio: Double {
        abs(spentSum) / autoBudgetAmount
    }
    var descriptionText: String {
        "\(abs(spentSum)) / \(autoBudgetAmount)"
    }
}
#Preview {
    BudgetsView(
        store: Store(initialState: Budgets.State(budgets: [.mock])) {
            Budgets()
        }
    )
}
