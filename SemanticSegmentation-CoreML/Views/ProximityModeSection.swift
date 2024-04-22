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
            NavigationLink {
                Form {
                    ProximityThresholdsSection(
                        objectProximityThreshold1: $objectProximityThreshold1,
                        objectProximityThreshold2: $objectProximityThreshold2,
                        objectProximityThreshold3: $objectProximityThreshold3,
                        objectProximityThreshold4: $objectProximityThreshold4
                    )
                }
                .navigationTitle("Thresholds")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Text("Thresholds")
                    Spacer()
                    Text(
                        [
                            objectProximityThreshold1,
                            objectProximityThreshold2,
                            objectProximityThreshold3,
                            objectProximityThreshold4,
                        ].map {
                            String(format: "%0.2f", $0)
                        }.joined(separator: ", ")
                    ).foregroundStyle(.secondary)
                }
            }
        }
    }
}
