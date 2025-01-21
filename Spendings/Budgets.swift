//
//  Budgets.swift
//  Spendings
//
//  Created by Hung Dao on 7/12/24.
//

import ComposableArchitecture
import SwiftUI
import Charts

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
            ScrollView {
                HStack {
                    Text("Balance: ")
                    Text("\(store.budgets.totalRemaining)")
                        .foregroundStyle(store.budgets.totalRemaining > 0 ? .green : .red)
                }
                Chart(store.budgets) { budget in
                    SectorMark(
                        angle: .value("Spent", budget.spentSum),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Category", budget.name))
                }
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        let frame = geometry[chartProxy.plotFrame!]
                        VStack {
                            Text("Total spent")
                                .font(.callout)
                            Text("\(store.budgets.totalSpent)")
                                .font(.title2.bold())
                                .foregroundStyle(.red)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
                .frame(minHeight: 300)
                .padding(.horizontal, 16)
                ForEach(store.budgets) { budget in
                    VStack {
                        NavigationLink(destination: {
                            TransactionsView(store: Store(initialState: Transactions.State(sourceId: budget.id, souceType: .budgets)) {
                                Transactions()
                            })
                            .navigationTitle(budget.name)
                        }, label: {
                            HStack {
                                budgetItemView(with: budget)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color(UIColor.label))
                                                            
                            }
                            
                        })
                        Divider()
                    }
                    .padding(.horizontal)
                }
            }
            .refreshable {
                store.send(.loadBudgets)
            }
            .padding(.top, 1)
            if store.isLoading {
                ProgressView()
            }
            
        }
    }

    @ViewBuilder
    func budgetItemView(with budget: Budget) -> some View {
        VStack(alignment: .leading) {
            Text("\(budget.name)")
                .foregroundStyle(Color(UIColor.label))
            if budget.spentRatio > 1 {
                ProgressView(value: 1) {
                    Text(budget.descriptionText)
                }
                .tint(.red)
                HStack {
                    Text("Remaining:")
                        .foregroundStyle(Color(UIColor.label))
                    Text("\(budget.remainingAmount)")
                        .foregroundStyle(.red)
                }
            } else {
                ProgressView(value: budget.spentRatio) {
                    Text("\(budget.descriptionText)")
                        .foregroundStyle(Color(UIColor.label))
                }
                HStack {
                    Text("Remaining:")
                        .foregroundStyle(Color(UIColor.label))
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

    var totalSpent: Int {
        var result: Int = 0
        for budget in self {
            result += budget.spentSum
        }
        return result
    }
}
#Preview {
    BudgetsView(
        store: Store(initialState: Budgets.State(budgets: Shared(value: [.mock, .mock, .mock, .mock, .mock, .mock]))) {
            Budgets()
        }
    )
}
