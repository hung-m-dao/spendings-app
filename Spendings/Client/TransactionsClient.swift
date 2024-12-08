//
//  TransactionsClient.swift
//  Spendings
//
//  Created by Hung Dao on 7/12/24.
//

import ComposableArchitecture
import Foundation

// MARK: - Models
// Root structure
struct TransactionsResponse: Codable {
    let data: [TransactionData]
}

// TransactionData structure
struct TransactionData: Codable {
    let attributes: Attributes
}

// Attributes structure
struct Attributes: Codable {
    let transactions: [Transaction]
}

// Transaction structure
struct Transaction: Codable, Equatable, Identifiable {
    let description: String
    let amount: String
    let id: String
    let budgetID: String
    
    enum CodingKeys: String, CodingKey {
        case id = "transaction_journal_id"
        case description
        case amount
        case budgetID = "budget_id"
    }
}

struct WithdrawalTransaction: Codable, Equatable {
    var description: String
    var amount: String
    var budgetID: String
    var sourceID: String
    let type: String = "withdrawal"
    let categoryName: String = NetworkConfiguration.currentUser
    var date: Date = Date()

    init(
        description: String = "",
        amount: String = "",
        budgetID: String = "",
        sourceID: String = ""
    ) {
        self.description = description
        self.amount = amount
        self.budgetID = budgetID
        self.sourceID = sourceID
    }
    
    enum CodingKeys: String, CodingKey {
        case description
        case amount
        case budgetID = "budget_id"
        case sourceID = "source_id"
        case categoryName = "category_name"
        case type
        case date
    }
}

struct WithDrawalTransactionRequest: Codable {
    let transactions: [WithdrawalTransaction]
}

struct TransactionSource: Codable, Equatable, Identifiable {
    let id: String
    let sourceName: String
    let sourceID: String

    static let credit: TransactionSource = TransactionSource(id: "1", sourceName: "Tín dụng", sourceID: "6")
    static let cash: TransactionSource = TransactionSource(id: "2", sourceName: "Tiền mặt", sourceID: "1")
}

@DependencyClient
struct TransactionsClient {
    var fetch: @Sendable (_ budgetID: String) async throws -> [Transaction]
    var create: @Sendable (_ transaction: WithdrawalTransaction) async throws -> ()
}

extension TransactionsClient: TestDependencyKey {
    static let testValue: TransactionsClient = Self()
    
    static let previewValue: TransactionsClient = Self(fetch: { _ in [.mock]}, create: { _ in ()})
}

extension DependencyValues {
    var transactionsClient: TransactionsClient {
        get { self[TransactionsClient.self] }
        set { self[TransactionsClient.self] = newValue }
    }
}

// MARK: - Live API

extension TransactionsClient: DependencyKey {
    static let liveValue: TransactionsClient = TransactionsClient(
        fetch: { budgetId in
            let data = try await APIClient().makeRequest(api: .budgetTransactions(budgetId: budgetId))
            let response = try JSONDecoder().decode(TransactionsResponse.self, from: data)
            return response.data.compactMap { $0.attributes.transactions.first }
        },
        create: { transaction in
            let _ = try await APIClient().makeRequest(api: .createTransaction(transaction: transaction))
            return
        }
    )
}

// MARK: - Mock
extension Transaction {
    static let mock = Self(description: "test descaaasdfasdfasdfasdfasdfasdfasdfasdf", amount: "23213.24123", id: "1", budgetID: "1")
}
