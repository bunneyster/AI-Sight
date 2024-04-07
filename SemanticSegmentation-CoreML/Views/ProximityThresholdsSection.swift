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
    var objectProximityThreshold1: Double
    @Binding
    var objectProximityThreshold2: Double
    @Binding
    var objectProximityThreshold3: Double
    @Binding
    var objectProximityThreshold4: Double

    var body: some View {
        HStack {
            VStack {
                Text("Threshold 1").font(.subheadline)
                    .multilineTextAlignment(.center)
                Picker(
                    selection: $objectProximityThreshold1,
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
                    selection: $objectProximityThreshold2,
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
                    selection: $objectProximityThreshold3,
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
                    selection: $objectProximityThreshold4,
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

#Preview {
    ProximityThresholdsSection(
        objectProximityThreshold1: .constant(0.75),
        objectProximityThreshold2: .constant(1.25),
        objectProximityThreshold3: .constant(1.75),
        objectProximityThreshold4: .constant(2.5)
    )
}
