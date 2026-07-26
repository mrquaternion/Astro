//
//  TrajectoryChart.swift
//  Astro
//
//  Created by Mathias La Rochelle on 2026-07-19.
//

import SwiftUI
import Charts

struct TrajectoryChartData {
    /// Stable identity of the chart sample.
    var id = UUID()
    /// Distance traveled at this sample.
    var distance: Double
    /// Elevation value at this sample.
    var value: Double // elevation
}

struct TrajectoryChart: View {
    
    /// Distance currently selected in the chart.
    @State private var selectedDistance: Double?
    
    /// Samples displayed by the trajectory chart.
    let data: [TrajectoryChartData]?
    
    /// Chart sample nearest the selected distance.
    var selectedX: TrajectoryChartData? {
        guard let selectedDistance, let data else { return nil }
        return data.min { abs($0.distance - selectedDistance) < abs($1.distance - selectedDistance) }
    }

    var body: some View {
        if let data {
            VStack(alignment: .leading) {
                Text("Simulated trajectory graph".capitalized)
                    .font(.title3)
                    .fontWeight(.semibold)
                    
                chart(data)
                
                Spacer()
            }
        } else {
            ContentUnavailableView("Trajectory has not been loaded yet.", systemImage: "bolt.horizontal.circle")
        }
    }

    private func chart(_ data: [TrajectoryChartData]) -> some View {
        Chart {
            ForEach(data, id: \.id) { point in
                LineMark(
                    x: .value("Distance", point.distance),
                    y: .value("Altitude", point.value)
                )
                
                AreaMark(
                    x: .value("Distance", point.distance),
                    y: .value("Altitude", point.value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.accent.opacity(0.35), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            if let selectedX {
                RuleMark(
                    x: .value("Selected", selectedX.distance),
                    yStart: .value("", 0),
                    yEnd: .value("", (data.map(\.value).max() ?? 0) + 50)
                )
                
                .annotation(position: .top) {
                    Text(String(format: "%.2f km", selectedX.value))
                }
                
                PointMark(
                    x: .value("Distance", selectedX.distance),
                    y: .value("Altitude", selectedX.value)
                )
            }
        }
        .chartXSelection(value: $selectedDistance)
        .chartXScale(domain: 0...(data.map(\.distance).max() ?? 0))
        .chartYScale(domain: 0...((data.map(\.value).max() ?? 0) + 150))
        .chartXAxisLabel("Distance from pad (km)")
        .chartYAxisLabel("Elevation (km)")
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
        .frame(height: 250)
    }
}
