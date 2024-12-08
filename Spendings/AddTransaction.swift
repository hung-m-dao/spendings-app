//
//  AddTransaction.swift
//  Spendings
//
//  Created by Hung Dao on 8/12/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct AddTransaction {
    @ObservableState
    struct State: Equatable {
        var isLoading: Bool = false
        @Shared var budgets: [Budget]
        var description: String = ""
        var amount: String = ""
        var selectedBudgetID: String = ""
        var selectedSourceID: String = ""
        @Presents var alert: AlertState<Never>?
        
        mutating func reset() {
            description = ""
            amount = ""
            selectedBudgetID = ""
            selectedSourceID = ""
            isLoading = false
        }
    }
    
    enum Action: BindableAction {
        case alert(PresentationAction<Never>)
        case binding(BindingAction<State>)
        case submitForm
        case formResponse(Result<(), any Error>)
    }
    
    @Dependency(\.transactionsClient) var client
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .submitForm:
                state.isLoading = true
                let transactionObject = WithdrawalTransaction(
                    description: state.description,
                    amount: state.amount,
                    budgetID: state.selectedBudgetID,
                    sourceID: state.selectedSourceID
                )
                return .run { send in
                    await send(.formResponse(Result { try await self.client.create(transactionObject)}))
                }
            case .formResponse(.failure):
                state.reset()
                state.alert = AlertState { TextState("Failed to create transaction !")}
                return .none
            case .formResponse(.success):
                state.reset()
                state.alert = AlertState { TextState("Successfully added transaction !")}
                return .none
            default:
                return .none
            }
        }
        .ifLet(\.alert, action: \.alert)
    }
}

struct AddTransactionView: View {
    @Bindable var store: StoreOf<AddTransaction>

    var body: some View {
        ZStack {
            Form {
                // Description
                Section(header: Text("Description")) {
                    TextField(
                        "Enter description",
                        text: $store.description
                    )
                }
                
                // Amount
                Section(header: Text("Amount")) {
                    TextField(
                        "Enter amount",
                        text: $store.amount
                    )
                    .keyboardType(.decimalPad)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            .fontWeight(.bold)
                        }
                    }
                }
                
                // Budget Picker
                Section(header: Text("Budget")) {
                    Picker(
                        selection: $store.selectedBudgetID,
                        label: EmptyView()
                        )
                     {
                         ForEach(store.budgets) { budget in
                             Text(budget.name).tag(budget.id)
                        }
                    }
                     .pickerStyle(.inline)
                }

                
                // Source Picker
                Section(header: Text("Source")) {
                    Picker(
                        "Select source",
                        selection: $store.selectedSourceID
                    ) {
                        ForEach([TransactionSource.cash, TransactionSource.credit]) { source in
                            Text(source.sourceName).tag(source.sourceID)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                }

                // Submit Button
                Button(action: {
                    store.send(.submitForm)
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity, maxHeight: 10)
                        .padding()
                        .foregroundColor(.white )
                        .background(shouldDisableSubmitButton ? .red : .blue )
                        .cornerRadius(8)
                }
                .disabled(shouldDisableSubmitButton)
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
            }
            .scrollDismissesKeyboard(.interactively)
            .alert($store.scope(state: \.alert, action: \.alert))
            
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    private var shouldDisableSubmitButton: Bool {
        store.amount.isEmpty || store.description.isEmpty || store.selectedBudgetID.isEmpty || store.selectedSourceID.isEmpty
    }
}

#Preview {
    AddTransactionView(store: Store(initialState: AddTransaction.State(budgets: Shared(value: [.mock]))) {
        AddTransaction()
    })
}
