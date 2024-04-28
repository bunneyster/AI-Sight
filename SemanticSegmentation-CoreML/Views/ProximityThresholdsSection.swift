//
//  ProximityThresholdsSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/6/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct ProximityThresholdsSection: View {
    @Binding
    var proximityThreshold1: Double
    @Binding
    var proximityThreshold2: Double
    @Binding
    var proximityThreshold3: Double
    @Binding
    var proximityThreshold4: Double

    var body: some View {
        HStack {
            VStack {
                Text("Threshold 1").font(.subheadline)
                    .multilineTextAlignment(.center)
                Picker(
                    selection: $proximityThreshold1,
                    label: Text("Threshold 1")
                ) {
                    ForEach(
                        Array(stride(from: 0.5, through: 5, by: 0.25)),
                        id: \.self
                    ) { value in
                        Text(String(format: "%.2f", value)).tag(value)
                    }
                }.pickerStyle(.wheel)
            }
            VStack {
                Text("Threshold 2").font(.subheadline)
                    .multilineTextAlignment(.center)
                Picker(
                    selection: $proximityThreshold2,
                    label: Text("Threshold 2")
                ) {
                    ForEach(
                        Array(stride(from: 0.5, through: 5, by: 0.25)),
                        id: \.self
                    ) { value in
                        Text(String(format: "%.2f", value)).tag(value)
                    }
                }.pickerStyle(.wheel)
            }
            VStack {
                Text("Threshold 3").font(.subheadline)
                    .multilineTextAlignment(.center)
                Picker(
                    selection: $proximityThreshold3,
                    label: Text("Threshold 3")
                ) {
                    ForEach(
                        Array(stride(from: 0.5, through: 5, by: 0.25)),
                        id: \.self
                    ) { value in
                        Text(String(format: "%.2f", value)).tag(value)
                    }
                }.pickerStyle(.wheel)
            }
            VStack {
                Text("Threshold 4").font(.subheadline)
                    .multilineTextAlignment(.center)
                Picker(
                    selection: $proximityThreshold4,
                    label: Text("Threshold 4")
                ) {
                    ForEach(
                        Array(stride(from: 0.5, through: 5, by: 0.25)),
                        id: \.self
                    ) { value in
                        Text(String(format: "%.2f", value)).tag(value)
                    }
                }.pickerStyle(.wheel)
            }
        }
    }
}
