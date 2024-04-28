//
//  ProximityModeSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct ProximityModeSection: View {
    @AppStorage(UserDefaults.Key.proximityThreshold1.rawValue)
    var proximityThreshold1: Double = 0.75
    @AppStorage(UserDefaults.Key.proximityThreshold2.rawValue)
    var proximityThreshold2: Double = 1.25
    @AppStorage(UserDefaults.Key.proximityThreshold3.rawValue)
    var proximityThreshold3: Double = 1.75
    @AppStorage(UserDefaults.Key.proximityThreshold4.rawValue)
    var proximityThreshold4: Double = 2.5

    var body: some View {
        Section(header: Text("Proximity Mode")) {
            NavigationLink {
                Form {
                    ProximityThresholdsSection(
                        proximityThreshold1: $proximityThreshold1,
                        proximityThreshold2: $proximityThreshold2,
                        proximityThreshold3: $proximityThreshold3,
                        proximityThreshold4: $proximityThreshold4
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
                            proximityThreshold1,
                            proximityThreshold2,
                            proximityThreshold3,
                            proximityThreshold4,
                        ].map {
                            String(format: "%0.2f", $0)
                        }.joined(separator: ", ")
                    ).foregroundStyle(.secondary)
                }
            }
        }
    }
}
