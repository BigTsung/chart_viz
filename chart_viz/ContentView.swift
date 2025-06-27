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
    @State private var manualData =
        "Label,Series 1,Series 2\nA,1,2\nB,2,3\nC,3,1"
    @State private var points: [ChartPoint] = [
        ChartPoint(series: "Series 1", label: "A", value: 1),
        ChartPoint(series: "Series 1", label: "B", value: 2),
        ChartPoint(series: "Series 1", label: "C", value: 3),
        ChartPoint(series: "Series 2", label: "A", value: 2),
        ChartPoint(series: "Series 2", label: "B", value: 3),
        ChartPoint(series: "Series 2", label: "C", value: 1),
    ]
    @State private var title = "Sample Chart"
    @State private var xAxisLabel = "X"
    @State private var yAxisLabel = "Y"
    @State private var showLegend = true
    @State private var verticalBars = true
    @State private var cornerRadius: Double = 0
    @State private var barWidth: Double = 10
    @State private var opacity: Double = 1.0
    @State private var showXAxis = true
    @State private var showYAxis = true
    @State private var color = Color.accentColor

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("Import CSV") { openCSV() }
                Spacer()
            }
            .padding(.bottom)

            HStack(alignment: .top) {
                Form {
                    Section("資料與標籤") {
                        TextEditor(text: $manualData)
                            .frame(height: 80)
                            .onChange(of: manualData) { _ in
                                points = parseCSV(manualData)
                            }
                        Button("套用資料") {
                            points = parseCSV(manualData)
                        }
                        TextField("標題", text: $title)
                        TextField("X 軸名稱", text: $xAxisLabel)
                        TextField("Y 軸名稱", text: $yAxisLabel)
                    }
                    Section("外觀") {
                        ColorPicker("主要色彩", selection: $color)
                        HStack {
                            Text("圓角大小")
                            Slider(value: $cornerRadius, in: 0...10)
                        }
                        HStack {
                            Text("寬度")
                            Slider(value: $barWidth, in: 2...30)
                        }
                        HStack {
                            Text("透明度")
                            Slider(value: $opacity, in: 0.2...1)
                        }
                    }
                    Section("軸線與圖例") {
                        Toggle("顯示圖例", isOn: $showLegend)
                        Toggle("直向呈現", isOn: $verticalBars)
                        Toggle("顯示 X 軸", isOn: $showXAxis)
                        Toggle("顯示 Y 軸", isOn: $showYAxis)
                    }
                    Section("輸出") {
                        HStack {
                            Button("PNG") { exportImage(type: .png) }
                            Button("JPEG") { exportImage(type: .jpeg) }
                            Button("PDF") { exportPDF() }
                        }
                    }
                }
                .frame(minWidth: 250)

                chartView
                    .padding()
                    .overlay(
                        Text(title)
                            .font(.title)
                            .padding([.top]),
                        alignment: .top
                    )
            }
            .padding()
            .frame(minWidth: 700, minHeight: 600)
        }
    }

    private func parseCSV(_ text: String) -> [ChartPoint] {
        var result: [ChartPoint] = []
        let rows = text.split(separator: "\n")
        guard let headerRow = rows.first else { return result }
        let headers = headerRow.split(separator: ",").map(String.init)
        let seriesNames = Array(headers.dropFirst())

        for row in rows.dropFirst() {
            let parts = row.split(separator: ",")
            guard parts.count >= 2 else { continue }
            let label = String(parts[0])
            for (index, series) in seriesNames.enumerated() {
                if parts.count > index + 1, let value = Double(parts[index + 1])
                {
                    result.append(
                        ChartPoint(series: series, label: label, value: value)
                    )
                }
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
        let multipleSeries = Set(points.map(\.series)).count > 1
        return Chart {
            ForEach(points) { point in
                if verticalBars {
                    BarMark(
                        x: .value(xAxisLabel, point.label),
                        y: .value(yAxisLabel, point.value),
                        width: .fixed(barWidth)
                    )
                    .applyStyle(
                                            series: point.series,
                                            multiple: multipleSeries,
                                            color: color,
                                            cornerRadius: cornerRadius,
                                            opacity: opacity
                                        )
                } else {
                    BarMark(
                        x: .value(yAxisLabel, point.value),
                        y: .value(xAxisLabel, point.label),
                        width: .fixed(barWidth)

                    )
                    .applyStyle(
                        series: point.series,
                        multiple: multipleSeries,
                        color: color,
                        cornerRadius: cornerRadius,
                        opacity: opacity
                    )
                }
            }
        }
        .chartLegend(showLegend ? .visible : .hidden)
        .chartXAxis(showXAxis ? .automatic : .hidden)
        .chartYAxis(showYAxis ? .automatic : .hidden)
        .frame(width: 400, height: 300)
    }

    private struct StyleModifier: ViewModifier {
            let series: String
            let multiple: Bool
            let color: Color
            let cornerRadius: Double
            let opacity: Double

            func body(content: Content) -> some View {
                if multiple {
                    content
                        .foregroundStyle(by: .value("Series", series))
                        .cornerRadius(cornerRadius)
                        .opacity(opacity)
                } else {
                    content
                        .foregroundStyle(color.opacity(opacity))
                        .cornerRadius(cornerRadius)
                }
            }
        }
    }

    private extension View {
        func applyStyle(
            series: String,
            multiple: Bool,
            color: Color,
            cornerRadius: Double,
            opacity: Double
        ) -> some View {
            modifier(
                ContentView.StyleModifier(
                    series: series,
                    multiple: multiple,
                    color: color,
                    cornerRadius: cornerRadius,
                    opacity: opacity
                )
            )
        }
}
#Preview {
    ContentView()
}
