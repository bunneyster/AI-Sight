//
//  ObjectIdentificationSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct ObjectIdentificationSection: View {
    @AppStorage("minObjectSizePercentage")
    var minObjectSizePercentage: Double = 0.01

    var body: some View {
        Section(header: Text("Object Identification")) {
            NavigationLink {
                Form {
                    Section(
                        header: Text("Minimum Object Size"),
                        footer: Text(
                            "Objects that occupy a lesser percentage of the screen will be ignored."
                        )
                    ) {
                        VStack {
                            Group {
                                Text("\(Int(round(minObjectSizePercentage * 100)))%")
                                Text(
                                    "\(Int(round(Double(ModelDimensions.deepLabV3.size) * minObjectSizePercentage))) pixels"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }.accessibilityHidden(true)
                            Slider(value: $minObjectSizePercentage, in: 0.01...1, step: 0.01) {
                                Text("Minimum object size")
                            } minimumValueLabel: {
                                Label("0%", systemImage: "square.grid.3x3.topleft.filled")
                                    .labelStyle(.iconOnly).accessibilityHidden(true)
                            } maximumValueLabel: {
                                Label("100%", systemImage: "square.grid.3x3.fill")
                                    .labelStyle(.iconOnly).accessibilityHidden(true)
                            }
                            .accessibility(
                                value: Text("\(Int(round(minObjectSizePercentage * 100)))%")
                            )
                        }
                    }
                }
                .navigationTitle("Object Identification")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Text("Minimum object size")
                    Spacer()
                    Text("\(Int(round(minObjectSizePercentage * 100)))%")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ObjectIdentificationSection()
}
