//
//  ObjectPropertiesSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct ObjectPropertiesSection: View {
    @AppStorage("minObjectSizePercentage")
    var minObjectSizePercentage: Double = 0.01

    var body: some View {
        Section(header: Text("Object Properties")) {
            NavigationLink {
                Form {
                    MinObjectSizePercentageSection(
                        minObjectSizePercentage: $minObjectSizePercentage
                    )
                }
                .navigationTitle("Object Properties")
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
    ObjectPropertiesSection()
}
