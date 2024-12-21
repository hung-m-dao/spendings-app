//
//  Transactions.swift
//  Spendings
//
//  Created by Hung Dao on 7/12/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Transactions {
    @ObservableState
    struct State: Equatable {
        var isLoading: Bool = false
        let sourceId: String
        let souceType: SourceType
        var transactions: [Transaction]?
        
        enum SourceType {
            case accounts
            case budgets
        }
    }

    enum Action {
        case loadTransactions
        case transactionsResponse(Result<[Transaction], any Error>)
    }
    
    @Dependency(\.transactionsClient) var client

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadTransactions:
                state.isLoading = true
                return .run { [id = state.sourceId, type = state.souceType] send in
                    await send(.transactionsResponse(Result { try await self.fetchTransaction(sourceId: id, sourceType: type)}))
                }
            case .transactionsResponse(.failure):
                state.isLoading = false
                state.transactions = []
                return .none
            case let .transactionsResponse(.success(response)):
                state.isLoading = false
                state.transactions = response
                return .none
            }
        }
    }
    
    private func fetchTransaction(sourceId: String, sourceType: State.SourceType) async throws -> [Transaction] {
        switch sourceType {
        case .accounts:
            try await client.fetchByAccounts(accountID: sourceId)
        case .budgets:
            try await client.fetchByBudgets(budgetID: sourceId)
        }
    }
}

struct TransactionsView: View {
    @Bindable var store: StoreOf<Transactions>
    
    var body: some View {
        ZStack {
            List {
                ForEach(store.transactions ?? []) { transaction in
                    HStack {
                        Text("\(transaction.description)")
                            .frame(maxWidth: 160, alignment: .leading)
                        Spacer()
                        Text("\(transaction.amount.toInt)")
                    }
                }
            }
            .refreshable {
                store.send(.loadTransactions)
            }
            if store.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            store.send(.loadTransactions)
        }
    }
}

private extension String {
    var toInt: Int {
        let doubleValue: Double = Double(self) ?? 0
        return Int(doubleValue)
    }
}

#Preview {
    TransactionsView(store: Store(initialState: Transactions.State(sourceId: "2", souceType: .budgets)) {
        Transactions()
    })
}
