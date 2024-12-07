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
        let budgetID: String
        var transactions: [Transaction]?
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
                return .run { [id = state.budgetID] send in
                    await send(.transactionsResponse(Result { try await self.client.fetch(budgetID: id)}))
                }
            case .transactionsResponse(.failure):
                state.transactions = []
                return .none
            case let .transactionsResponse(.success(response)):
                state.transactions = response
                return .none
            }
        }
    }
}

struct TransactionsView: View {
    @Bindable var store: StoreOf<Transactions>
    
    var body: some View {
        if let transactions = store.transactions {
            List {
                ForEach(transactions) { transaction in
                    HStack {
                        Text("\(transaction.description)")
                            .frame(maxWidth: 160, alignment: .leading)
                        Spacer()
                        Text("\(transaction.amount.formattedDouble)")
                    }
                }
            }
        } else {
            ProgressView()
                .onAppear {
                    store.send(.loadTransactions)
                }
        }
        
    }
}

private extension String {
    var formattedDouble: String {
        let doubleValue: Double = Double(self) ?? 0.0
        return String(format: "%.1f", doubleValue)
    }
}

#Preview {
    TransactionsView(store: Store(initialState: Transactions.State(budgetID: "2")) {
        Transactions()
    })
}
