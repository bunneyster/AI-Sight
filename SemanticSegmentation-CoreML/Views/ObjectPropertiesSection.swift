//
//  ObjectPropertiesSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct ObjectPropertiesSection: View {
    @AppStorage(UserDefaults.Key.minObjectSizePercentage.rawValue)
    var minObjectSizePercentage: Double = 0.01
    @AppStorage(UserDefaults.Key.objectDepthPercentile.rawValue)
    var objectDepthPercentile: Double = 0.1

    var body: some View {
        Section(header: Text("Object Properties")) {
            NavigationLink {
                Form {
                    MinObjectSizePercentageSection(
                        minObjectSizePercentage: $minObjectSizePercentage
                    )
                }
                .navigationTitle("Minimum Object Size")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Text("Minimum object size")
                    Spacer()
                    Text("\(Int(round(minObjectSizePercentage * 100)))%")
                        .foregroundStyle(.secondary)
                }
            }

            NavigationLink {
                Form {
                    DepthComputationSection(objectDepthPercentile: $objectDepthPercentile)
                }
                .navigationTitle("Depth Computation")
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
