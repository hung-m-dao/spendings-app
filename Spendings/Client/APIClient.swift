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
    
    var path: String {
        switch self {
        case .getBudgets:
            return "/v1/budgets"
        case let .budgetTransactions(budgetId):
            return "/v1/budgets/\(budgetId)/transactions"
        }
    }
    
    var method: String {
        switch self {
        case .getBudgets:
            return "GET"
        case .budgetTransactions:
            return "GET"
        }
    }

    var queryItems: [URLQueryItem]? {
        startAndEndQueryItems(ofMonth: Calendar.current.component(.month, from: Date()))
    }

    func startAndEndQueryItems(ofMonth month: Int) -> [URLQueryItem] {
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
            URLQueryItem(name: "end", value: lastDay)
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
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for valid HTTP response
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw NetworkError.invalidHTTPCode(httpResponse.statusCode)
        }
        return data
    }
}
