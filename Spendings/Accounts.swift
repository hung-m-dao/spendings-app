//
//  AddTransaction.swift
//  Spendings
//
//  Created by Hung Dao on 8/12/24.
//

import ComposableArchitecture
import SwiftUI
import Charts

@Reducer
struct Accounts {
    @ObservableState
    struct State: Equatable {
        var isLoading: Bool = false
        var accounts: [Account]?
    }
    
    enum Action {
        case loadAccounts
        case accountsResponse(Result<[Account], any Error>)
    }
    
    @Dependency(\.accountsClient) var client
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadAccounts:
                state.isLoading = true
                return .run { send in
                    await send(.accountsResponse(Result { try await self.client.fetch()}))
                }
            case let .accountsResponse(.success(response)):
                state.isLoading = false
                state.accounts = response
                return .none
            case .accountsResponse(.failure):
                state.isLoading = false
                state.accounts = []
                return .none
            }
        }
    }
}

struct AccountsView: View {
    @Bindable var store: StoreOf<Accounts>
    
    var body: some View {
        ZStack {
            if let accounts = store.accounts {
                List {
                    ForEach(accounts) { account in
                        NavigationLink(destination: {
                            TransactionsView(store: Store(initialState: Transactions.State(sourceId: account.id, souceType: .accounts)) {
                                Transactions()
                            })
                            .navigationTitle(account.name)
                        }, label: {
                            accountItemView(with: account)
                        })
                    }
                    
                }
                .refreshable {
                    store.send(.loadAccounts)
                }
            
            }
            if store.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            store.send(.loadAccounts)
        }
    }
    
    @ViewBuilder
    func accountItemView(with account: Account) -> some View {
        VStack(alignment: .leading) {
            Text("\(account.name)")
            HStack {
                Text("Balance:")
                Text("\(account.currentBalance)")
                    .foregroundStyle(account.currentBalance > 0 ? .green : .red)
                    
            }
        }
    }
}

#Preview {
    AccountsView(
        store:
            Store(initialState: Accounts.State(isLoading: false, accounts: [.mock])) {
        Accounts()
    })
}
