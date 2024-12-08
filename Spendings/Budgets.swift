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
        @Shared var budgets: [Budget]
        var isLoading: Bool = false
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
                state.isLoading = true
                return .run { send in
                    await send(.budgetsResponse(Result {try await self.client.fetch()}))
                }
            case let .budgetsResponse(.success(response)):
                state.isLoading = false
                state.$budgets.withLock { $0 = response}
                return .none
            case .budgetsResponse(.failure):
                state.isLoading = false
                state.$budgets.withLock { $0 = []}
                return .none
            }
        }
    }
}

struct BudgetsView: View {
    @Bindable var store: StoreOf<Budgets>

    var body: some View {
        ZStack {
            List {
                ForEach(store.budgets) { budget in
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
            if store.isLoading {
                ProgressView("Submitting... ")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
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
        store: Store(initialState: Budgets.State(budgets: Shared(value: [.mock]))) {
            Budgets()
        }
    )
}
