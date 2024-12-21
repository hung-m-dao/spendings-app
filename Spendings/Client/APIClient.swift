//
//  RequestBuilder.swift
//  Spendings
//
//  Created by Hung Dao on 7/12/24.
//
import Foundation

enum API {
    case getBudgets
    case budgetTransactions(budgetId: String)
    case createTransaction(transaction: WithdrawalTransaction)
    case getAccounts
    case accountTransactions(accountId: String)

    var path: String {
        switch self {
        case .getBudgets:
            return "/v1/budgets"
        case let .budgetTransactions(budgetId):
            return "/v1/budgets/\(budgetId)/transactions"
        case .createTransaction:
            return "/v1/transactions"
        case .getAccounts:
            return "/v1/accounts"
        case let .accountTransactions(accountId):
            return "/v1/accounts/\(accountId)/transactions"
        }
    }
    
    var method: String {
        switch self {
        case .getBudgets:
            return "GET"
        case .budgetTransactions, .accountTransactions:
            return "GET"
        case .createTransaction:
            return "POST"
        case .getAccounts:
            return "GET"
        }
    }
    
    var body: Data? {
        switch self {
        case let .createTransaction(transaction):
            let transactionRequest: WithDrawalTransactionRequest = WithDrawalTransactionRequest(transactions: [transaction])
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try? encoder.encode(transactionRequest)
        default:
            return nil
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .createTransaction:
            return ["accept": "application/vnd.api+json", "Content-Type": "application/json"]
        default:
            return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .createTransaction:
            return nil
        case .getAccounts:
            return [URLQueryItem(name: "type", value: "asset")]
        default:
            return startAndEndQueryItems(ofMonth: Calendar.current.component(.month, from: Date()))
        }
    }

    private func startAndEndQueryItems(ofMonth month: Int) -> [URLQueryItem] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // Ensure consistent formatting
        
        // Get the current year
        let year = calendar.component(.year, from: Date())
        
        // Create the first day of the month
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        guard let firstDayDate = calendar.date(from: dateComponents) else {
            return []
        }
        
        // Calculate the last day of the month
        guard let range = calendar.range(of: .day, in: .month, for: firstDayDate),
              let lastDayDate = calendar.date(byAdding: .day, value: range.count - 1, to: firstDayDate) else {
            return []
        }
        
        // Format the dates as YYYY-MM-DD
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let firstDay = dateFormatter.string(from: firstDayDate)
        let lastDay = dateFormatter.string(from: lastDayDate)
        
        return [
            URLQueryItem(name: "start", value: firstDay),
            URLQueryItem(name: "end", value: lastDay),
            URLQueryItem(name: "limit", value: "10")
        ]
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidHTTPCode(Int)
    case general
}

struct APIClient {
    let baseUrl: String
    
    init(baseUrl: String = NetworkConfiguration.baseUrl) {
        self.baseUrl = baseUrl
    }

    func makeRequest(api: API) async throws -> Data {
        guard var components = URLComponents(string: "\(baseUrl)\(api.path)") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = api.queryItems
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = api.method
        request.setValue(NetworkConfiguration.token, forHTTPHeaderField: "Authorization")
        if let body = api.body {
            request.httpBody = body
        }
        
        if let headers = api.headers {
            headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        print(response)
        // Check for valid HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        
        // Print response body
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response Body: \(jsonString)")
        } else {
            print("Failed to decode response body.")
        }
        
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw NetworkError.invalidHTTPCode(httpResponse.statusCode)
        }
        return data
    }
}
