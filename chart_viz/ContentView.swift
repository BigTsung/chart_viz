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
                }

                Section("軸線與圖例") {
                    Toggle("顯示圖例", isOn: $showLegend)
                    Toggle("直向呈現", isOn: $verticalBars)
                    Toggle("顯示 X 軸", isOn: $showXAxis)
                    Toggle("顯示 Y 軸", isOn: $showYAxis)
                }
                //
                Section("輸出") {
                    HStack {
                        Button("PNG") { exportImage(type: .png) }
                        Button("JPEG") { exportImage(type: .jpeg) }
                        Button("PDF") { exportPDF() }
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
            ForEach(points) { point in
                if verticalBars {
                    BarMark(
                        x: .value(xAxisLabel, point.label),
                        y: .value(yAxisLabel, point.value),
                        width: .fixed(barWidth)
                    )
                    .foregroundStyle(color.opacity(opacity))
                    .cornerRadius(cornerRadius)
                } else {
                    BarMark(
                        x: .value(yAxisLabel, point.value),
                        y: .value(xAxisLabel, point.label),
                        width: .fixed(barWidth)

                    )
                    .foregroundStyle(color.opacity(opacity))
                    .cornerRadius(cornerRadius)
                }
            }
        }
        .chartLegend(showLegend ? .visible : .hidden)
        .chartXAxis(showXAxis ? .automatic : .hidden)
        .chartYAxis(showYAxis ? .automatic : .hidden)
        .frame(width: 400, height: 300)
    }
}
#Preview {
    ContentView()
}
