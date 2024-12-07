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
    
    enum CodingKeys: String, CodingKey {
        case id = "transaction_journal_id"
        case description
        case amount
    }
}

@DependencyClient
struct TransactionsClient {
    var fetch: @Sendable (_ budgetID: String) async throws -> [Transaction]
}

extension TransactionsClient: TestDependencyKey {
    static let testValue: TransactionsClient = Self()
    
    static let previewValue: TransactionsClient = Self(fetch: { _ in [.mock]})
}

extension DependencyValues {
    var transactionsClient: TransactionsClient {
        get { self[TransactionsClient.self] }
        set { self[TransactionsClient.self] = newValue }
    }
}

// MARK: - Live API

extension TransactionsClient: DependencyKey {
    static let liveValue: TransactionsClient = TransactionsClient(fetch: { budgetId in
        let data = try await APIClient().makeRequest(api: .budgetTransactions(budgetId: budgetId))
        let response = try JSONDecoder().decode(TransactionsResponse.self, from: data)
        return response.data.compactMap { $0.attributes.transactions.first }
        
    })
}

// MARK: - Mock
extension Transaction {
    static let mock = Self(description: "test descaaasdfasdfasdfasdfasdfasdfasdfasdf", amount: "23213.24123", id: "1")
}
