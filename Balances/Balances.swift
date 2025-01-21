//
//  Balances.swift
//  Balances
//
//  Created by Hung Dao on 21/1/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> AccountsEntry {
        AccountsEntry.mock
    }

    func getSnapshot(in context: Context, completion: @escaping (AccountsEntry) -> ()) {
        let entry = AccountsEntry.mock
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let nextEntryDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        Task {
            let accounts = try? await WidgetClient.liveValue.fetch()
            let entry = AccountsEntry(date: currentDate, accounts: accounts ?? [])
            let timeline = Timeline(entries: [entry], policy: .after(nextEntryDate))
            completion(timeline)
        }
    }
}

struct AccountsEntry: TimelineEntry {
    let date: Date
    let accounts: [Account]
}

extension AccountsEntry {
    static var mock: AccountsEntry {
        return AccountsEntry(date: Date(), accounts: [.mock, .mock])
    }
}

struct BalancesEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Label("Balances", systemImage: "dongsign.circle")
                .labelStyle(TrailingIconLabelStyle())
                .padding(.bottom, 20)
            ForEach(entry.accounts) { account in
                accountItemView(with: account)
            }
            Spacer()
        }
    }

    @ViewBuilder
    func accountItemView(with account: Account) -> some View {
        HStack {
            Text("\(account.name)")
            Spacer()
            Text("\(account.currentBalance)")
                .foregroundStyle(account.currentBalance > 0 ? Color.rosePineGreen : Color.rosePineError)
                
        }
        .padding(.bottom, 10)
    }
}

struct Balances: Widget {
    let kind: String = "Balances"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BalancesEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.rosePineBackground
                }
        }
        .configurationDisplayName("Balances")
        .description("Displaying balances for your accounts")
    }
}

extension Color {
    static var rosePineBackground: Color {
        Color(red: 35/255, green: 33/255, blue: 54/255)
    }
    
    static var rosePineError: Color {
        Color(red: 235/255, green: 111/255, blue: 146/255)
    }
    
    static var rosePineGreen: Color {
        Color(red: 62/255, green: 143/255, blue: 176/255)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}
