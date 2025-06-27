//
//  DataModel.swift
//  chart_viz
//
//  Created by Chiu on 2025/6/27.
//

import Foundation
import SwiftUI

struct ChartPoint: Identifiable {
    let id = UUID()
    var label: String
    var value: Double
}

enum ChartKind: String, CaseIterable, Identifiable {
    case bar = "Bar"
    case line = "Line"
    case pie = "Pie"

    var id: String { rawValue }
}
