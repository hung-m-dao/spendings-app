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
        var shouldShowSpinner: Bool = false
        var fetchedTransactions: [Transaction]?
    }
    
    enum SourceType {
        case accounts
        case budgets
    }

    enum Action {
        case loadTransactions
        case transactionsResponse(Result<[Transaction], any Error>)
        case toggle
    }
    
    @Dependency(\.transactionsClient) var client

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadTransactions:
                return .run {  send in
                    await send(.transactionsResponse(Result { try await self.client.fetchByAccounts(accountID: "1")}))
                }
            case .transactionsResponse(.failure):
                state.fetchedTransactions = []
                return .none
            case let .transactionsResponse(.success(response)):
                state.fetchedTransactions = response
                return .none
            case .toggle:
                state.shouldShowSpinner.toggle()
                return .none
            }
        }
    }
    
    private func fetchTransaction(sourceId: String, sourceType: SourceType) async throws -> [Transaction] {
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
                ForEach(store.fetchedTransactions ?? []) {
                    fetchedTransaction in
                    Text("\(fetchedTransaction.description)")
                }
//                ForEach(store.fetchedTransactions) { transaction in
//                    HStack {
//                        Text("\(transaction.description)")
//                            .frame(maxWidth: 160, alignment: .leading)
//                        Spacer()
//                        Text("\(transaction.amount.toInt)")
//                    }
//                }
            }
            .refreshable {
                await store.send(.loadTransactions).finish()
            }
            Button(action: {
                store.send(.loadTransactions)
            }) {
                Text("Fetch")
            }
            if store.shouldShowSpinner {
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
    TransactionsView(store: Store(initialState: Transactions.State()) {
        Transactions()
    })
}
