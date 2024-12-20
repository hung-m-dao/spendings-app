//
//  AccountsClient.swift
//  Spendings
//
//  Created by Hung Dao on 20/12/24.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

struct AccountsResponse: Codable {
    let data: [Account]
}

struct Account: Codable, Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let currentBalance: Int
    
    init() {
        id = ""
        name = "account name"
        currentBalance = 100
    }
    
    enum ContainerCodingKeys: String, CodingKey {
        case id
        case attributes
    }
    
    enum AttributesKeys: String, CodingKey {
        case name
        case currentBalance = "current_balance"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContainerCodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let attributesContainer = try container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
        name = try attributesContainer.decode(String.self, forKey: .name)
        let balanceString = try attributesContainer.decode(String.self, forKey: .currentBalance)
        currentBalance = Int(Double(balanceString) ?? 0)
    }
}

// MARK: - API client interface

@DependencyClient
struct AccountsClient {
    var fetch: @Sendable () async throws -> [Account]
    
}

extension AccountsClient: TestDependencyKey {
    static let previewValue: AccountsClient = Self(fetch: { [.mock]})
    static let testValue: AccountsClient = Self()
}

extension DependencyValues {
    var accountsClient: AccountsClient {
        get { self[AccountsClient.self] }
        set { self[AccountsClient.self] = newValue }
    }
}

extension AccountsClient: DependencyKey {
    static var liveValue = AccountsClient(fetch: {
        let data = try await APIClient().makeRequest(api: .getAccounts)
        let response = try JSONDecoder().decode(AccountsResponse.self, from: data)
        return response.data
    })
}

extension Account {
    static let mock = Self()
}
