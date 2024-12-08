//
//  BudgetsClient.swift
//  Spendings
//
//  Created by Hung Dao on 7/12/24.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

struct BudgetResponse: Codable {
    let data: [Budget]
}
struct Budget: Codable, Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let spentSum: Int
    let autoBudgetAmount: Int
    
    init() {
        id = ""
        name = "budget name"
        spentSum = 100
        autoBudgetAmount = 1000
    }
    enum ContainerCodingKeys: String, CodingKey {
        case id
        case attributes
    }
    
    enum AttributesKeys: String, CodingKey {
        case name
        case autoBudgetAmount = "auto_budget_amount"
        case spent
    }
    
    struct Spent: Codable {
        let sum: String
    }
    enum SpentKeys: String, CodingKey {
        case sum
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContainerCodingKeys.self)
        let attributesContainer = try container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
        id = try container.decode(String.self, forKey: .id)
        name = try attributesContainer.decode(String.self, forKey: .name)
        let stringAmount = try attributesContainer.decode(String.self, forKey: .autoBudgetAmount)
        autoBudgetAmount = Int(Double(stringAmount) ?? 0)
        let spentArray = try attributesContainer.decode([Spent].self, forKey: .spent)
        let spentSumString = spentArray.first?.sum
        if let spentSumString {
            spentSum = Int(Double(spentSumString) ?? 0)
        } else {
            spentSum = 0
        }
    }
}

// MARK: - API client interface

@DependencyClient
struct BudgetClient {
    var fetch: @Sendable () async throws -> [Budget]
}

extension BudgetClient: TestDependencyKey {
    static let previewValue: BudgetClient = Self(fetch: { [.mock]})
    
    static let testValue: BudgetClient = Self()
}

extension DependencyValues {
    var budgetClient: BudgetClient {
        get { self[BudgetClient.self] }
        set { self[BudgetClient.self] = newValue }
    }
}

// MARK: - Live API

extension BudgetClient: DependencyKey {
    static let liveValue = BudgetClient(
        fetch: {
            let data = try await APIClient().makeRequest(api: .getBudgets)
            let response = try JSONDecoder().decode(BudgetResponse.self, from: data)
            return response.data
        }
    )
}

// MARK: - Mock

extension Budget {
    static let mock = Self()
}
