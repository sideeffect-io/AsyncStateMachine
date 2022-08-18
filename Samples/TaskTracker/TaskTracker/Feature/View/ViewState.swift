//
//  ViewState.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 16/02/2022.
//

import Foundation
import SwiftUI

enum ViewState: Hashable {
    case displayItems([Item])
    case displayProgress([Item])
    case displayFailure([Item])

    struct Item: Identifiable, Hashable {
        let id: String
        let startDate: String
        let timeSpan: String
        let description: String
        let startGradientColor: Color
        let endGradientColor: Color
    }
}

@Sendable func mapStateToViewState(state: State) -> ViewState {
    switch state {
      case .loading: return .displayProgress([])
      case .loaded(let entries): return .displayItems(entries.map { mapEntryToItem($0) })
      case .adding(let entry, let entries):
        let items = entries.map { mapEntryToItem($0) }
        let itemToAdd = mapEntryToItem(entry)
        return .displayProgress([itemToAdd] + items)
      case .removing(let entriesToRemove, let entries):
        let entriesToRemove = entriesToRemove.map { $0.id }
        let items = entries.filter { entry in !entriesToRemove.contains(where: { $0 == entry.id }) }
        return .displayProgress(items.map { mapEntryToItem($0) })
      case .failed: return .displayFailure([])
    }
}

extension ViewState {
    var shouldDisplayAlert: Binding<Bool> {
        if case .displayFailure = self {
            return Binding {
                true
            } set: { _ in
            }
        }
        return .constant(false)
    }

    var shouldDisplayProgress: Bool {
        if case .displayProgress = self { return true }
        return false
    }

    var items: [Item] {
        switch self {
        case
            let .displayItems(items),
            let .displayFailure(items),
            let .displayProgress(items): return items
        }
    }
}

var timeSpanformatter: DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.hour, .minute, .second]
    return formatter
}

func mapEntryToItem(_ entry: Entry) -> ViewState.Item {
    let id = entry.id
    let startDate = entry.startDate.formatted(date: .abbreviated, time: .shortened)
    let timeInterval = entry.endDate.timeIntervalSince(entry.startDate)
    let timeSpan = timeSpanformatter.string(from: timeInterval) ?? "unknown"
    let description = entry.description

    let startGradientColor: Color

    switch timeInterval {
    case 0...30: startGradientColor = .green
    case 31...60: startGradientColor = .blue
    case 61...120: startGradientColor = .orange
    default: startGradientColor = .pink
    }

    return ViewState.Item(
        id: id,
        startDate: startDate,
        timeSpan: timeSpan,
        description: description,
        startGradientColor: startGradientColor,
        endGradientColor: transposeColor(startGradientColor)
    )
}

func transposeColor(_ color: Color) -> Color {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    return Color(.sRGB, red: red * 1.5, green: green * 1.5, blue: blue * 1.5, opacity: alpha)
}
