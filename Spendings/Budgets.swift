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
            VStack {
                HStack {
                    Text("Total balance: ")
                    Text("\(store.budgets.totalRemaining)")
                        .foregroundStyle(store.budgets.totalRemaining > 0 ? .green : .red)
                }
                List {
                    ForEach(store.budgets) { budget in
                        NavigationLink(destination: {
                            TransactionsView(store: Store(initialState: Transactions.State(sourceId: budget.id, souceType: .budgets)) {
                                Transactions()
                            })
                            .navigationTitle(budget.name)
                        }, label: {
                            budgetItemView(with: budget)
                        })
                        
                    }
                }
                .refreshable {
                    store.send(.loadBudgets)
                }
                
            }
            
            if store.isLoading {
                ProgressView()
            }
            
        }
    }

    @ViewBuilder
    func budgetItemView(with budget: Budget) -> some View {
        VStack(alignment: .leading) {
            Text("\(budget.name)")
            if budget.spentRatio > 1 {
                ProgressView(value: 1) {
                    Text(budget.descriptionText)
                    
                }
                .tint(.red)
                HStack {
                    Text("Remaining:")
                    Text("\(budget.remainingAmount)")
                        .foregroundStyle(.red)
                }
            } else {
                ProgressView(value: budget.spentRatio) {
                    Text("\(budget.descriptionText)")
                }
                HStack {
                    Text("Remaining:")
                    Text("\(budget.remainingAmount, format: .number)")
                        .foregroundStyle(.green)
                }
            }
            
        }
    }
}

private extension Budget {
    var spentRatio: Double {
        Double(abs(spentSum)) / Double(autoBudgetAmount)
    }
    var descriptionText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let spentString = formatter.string(from: abs(spentSum) as NSNumber) ?? ""
        let budgetAmountString = formatter.string(from: autoBudgetAmount as NSNumber) ?? ""
        return "\(spentString) / \(budgetAmountString)"
    }

    var remainingAmount: Int {
        autoBudgetAmount - abs(spentSum)
    }
}

private extension Array where Element == Budget {
    var totalRemaining: Int {
        var result: Int = 0
        for budget in self {
            result += (budget.autoBudgetAmount - abs(budget.spentSum))
        }
        return result
    }
}
#Preview {
    BudgetsView(
        store: Store(initialState: Budgets.State(budgets: Shared(value: [.mock]))) {
            Budgets()
        }
    )
}
