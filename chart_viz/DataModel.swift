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

// Only bar charts are supported so the kind enum has been removed.
