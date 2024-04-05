//
//  ObjectDepthSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct ObjectDepthSection: View {
    @AppStorage("objectDepthPercentile")
    var objectDepthPercentile: Double = 0.1

    var body: some View {
        Section(header: Text("Object Depth")) {
            NavigationLink {
                Form {
                    Section(
                        header: Text("Depth Computation"),
                        footer: Text(
                            "Selects which of the object's LiDAR measurements to use as its representative depth."
                        )
                    ) {
                        VStack {
                            Text("\(Int(round(objectDepthPercentile * 100)))th Percentile")
                            Slider(value: $objectDepthPercentile, in: 0.01...1, step: 0.01) {
                                Text("Object depth percentile")
                            } minimumValueLabel: {
                                Label(
                                    "0th %ile",
                                    systemImage: "slider.horizontal.below.square.filled.and.square"
                                ).labelStyle(.iconOnly).accessibilityHidden(true)
                            } maximumValueLabel: {
                                Label(
                                    "100th %ile",
                                    systemImage: "slider.horizontal.below.square.and.square.filled"
                                ).labelStyle(.iconOnly).accessibilityHidden(true)
                            }
                            .accessibility(
                                value: Text(
                                    "\(Int(round(objectDepthPercentile * 100)))th percentile"
                                )
                            )
                        }
                    }
                }
                .navigationTitle("Object Depth")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Text("Depth computation")
                    Spacer()
                    Text("\(Int(round(objectDepthPercentile * 100)))th percentile")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ObjectDepthSection()
}
