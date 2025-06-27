//
//  ContentView.swift
//  chart_viz
//
//  Created by Chiu on 2025/6/27.
//

import AppKit
import Charts
import SwiftUI

struct ContentView: View {
    @State private var manualData = "Label,Value\nA,1\nB,2\nC,3"
    @State private var points: [ChartPoint] = [
        ChartPoint(label: "A", value: 1),
        ChartPoint(label: "B", value: 2),
        ChartPoint(label: "C", value: 3),
    ]
    @State private var chartType: ChartKind = .bar
    @State private var title = "Sample Chart"
    @State private var xAxisLabel = "X"
    @State private var yAxisLabel = "Y"
    @State private var showLegend = true
    @State private var lineDash = false
    @State private var color = Color.accentColor

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Picker("Chart", selection: $chartType) {
                    ForEach(ChartKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                Button("Import CSV") { openCSV() }
                Spacer()
            }
            .padding(.bottom)

            Chart {
                switch chartType {
                case .bar:
                    ForEach(points) { point in
                        BarMark(
                            x: .value(xAxisLabel, point.label),
                            y: .value(yAxisLabel, point.value)
                        )
                        .foregroundStyle(color)
                    }
                case .line:
                    ForEach(points) { point in
                        LineMark(
                            x: .value(xAxisLabel, point.label),
                            y: .value(yAxisLabel, point.value)
                        )
                        .foregroundStyle(color)
                        .lineStyle(
                            StrokeStyle(lineWidth: 2, dash: lineDash ? [5] : [])
                        )
                    }
                case .pie:
                    ForEach(points) { point in
                        SectorMark(
                            angle: .value(yAxisLabel, point.value),
                            innerRadius: .ratio(0.5)
                        )
                        .foregroundStyle(by: .value(xAxisLabel, point.label))
                    }
                }
            }
            .chartLegend(showLegend ? .visible : .hidden)
            .frame(height: 300)
            .padding()
            .overlay(
                Text(title)
                    .font(.title)
                    .padding([.top]),
                alignment: .top
            )

            Form {
                Section("Data") {
                    TextEditor(text: $manualData)
                        .frame(height: 80)
                    Button("Apply Data") {
                        points = parseCSV(manualData)
                    }
                }
                Section("Labels") {
                    TextField("Title", text: $title)
                    TextField("X Axis", text: $xAxisLabel)
                    TextField("Y Axis", text: $yAxisLabel)
                }
                Section("Style") {
                    Toggle("Show Legend", isOn: $showLegend)
                    Toggle("Dashed Line", isOn: $lineDash)
                    ColorPicker("Color", selection: $color)
                }
                Section("Export") {
                    HStack {
                        Button("PNG") { exportImage(type: .png) }
                        Button("JPEG") { exportImage(type: .jpeg) }
                        Button("PDF") { exportPDF() }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 600)
    }

    private func parseCSV(_ text: String) -> [ChartPoint] {
        var result: [ChartPoint] = []
        let rows = text.split(separator: "\n")
        for row in rows.dropFirst() {  // skip header
            let parts = row.split(separator: ",")
            if parts.count >= 2, let value = Double(parts[1]) {
                result.append(ChartPoint(label: String(parts[0]), value: value))
            }
        }
        return result
    }

    private func openCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .data]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url,
            let text = try? String(contentsOf: url)
        {
            manualData = text
            points = parseCSV(text)
        }
    }

    private enum ImageType { case png, jpeg }

    private func exportImage(type: ImageType) {
        let renderer = ImageRenderer(content: chartView)
        if let image = renderer.nsImage {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [type == .png ? .png : .jpeg]
            if panel.runModal() == .OK, let url = panel.url {
                guard let tiff = image.tiffRepresentation,
                    let rep = NSBitmapImageRep(data: tiff)
                else { return }
                let data = rep.representation(
                    using: type == .png ? .png : .jpeg,
                    properties: [:]
                )
                try? data?.write(to: url)
            }
        }
    }

    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        if panel.runModal() == .OK, let url = panel.url {
            let hosting = NSHostingView(rootView: chartView)
            hosting.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
            let data = hosting.dataWithPDF(inside: hosting.bounds)
            try? data.write(to: url)
        }
    }

    private var chartView: some View {
        Chart {
            switch chartType {
            case .bar:
                ForEach(points) { point in
                    BarMark(
                        x: .value(xAxisLabel, point.label),
                        y: .value(yAxisLabel, point.value)
                    )
                    .foregroundStyle(color)
                }
            case .line:
                ForEach(points) { point in
                    LineMark(
                        x: .value(xAxisLabel, point.label),
                        y: .value(yAxisLabel, point.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(
                        StrokeStyle(lineWidth: 2, dash: lineDash ? [5] : [])
                    )
                }
            case .pie:
                ForEach(points) { point in
                    SectorMark(
                        angle: .value(yAxisLabel, point.value),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(by: .value(xAxisLabel, point.label))
                }
            }
        }
        .chartLegend(showLegend ? .visible : .hidden)
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ContentView()
}
