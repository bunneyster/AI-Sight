//
//  MinObjectSizePercentageNavigationLink.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/5/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct MinObjectSizePercentageSection: View {
    @Binding
    var minObjectSizePercentage: Double

    var body: some View {
        Section {
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
        } footer: {
            Text(
                "Objects that occupy a lesser percentage of the screen will be ignored."
            )
        }
    }
}

#Preview {
    MinObjectSizePercentageSection(minObjectSizePercentage: .constant(0.01))
}
