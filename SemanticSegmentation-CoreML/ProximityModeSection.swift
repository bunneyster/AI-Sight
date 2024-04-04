//
//  ProximityModeSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct ProximityModeSection: View {
    @AppStorage("objectProximityThreshold1")
    var objectProximityThreshold1: Double = 0.75
    @AppStorage("objectProximityThreshold2")
    var objectProximityThreshold2: Double = 1.25
    @AppStorage("objectProximityThreshold3")
    var objectProximityThreshold3: Double = 1.75
    @AppStorage("objectProximityThreshold4")
    var objectProximityThreshold4: Double = 2.5

    var body: some View {
        Section(header: Text("Proximity Mode")) {
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
}

#Preview {
    ProximityModeSection()
}
