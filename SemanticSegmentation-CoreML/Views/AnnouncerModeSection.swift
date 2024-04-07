//
//  AnnouncerModeSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/6/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct AnnouncerModeSection: View {
    @AppStorage("announcerDepthInterval")
    var announcerDepthInterval: Double = 0.5
    @AppStorage("announcerDepthMargin")
    var announcerDepthMargin: Double = 0.2
    @AppStorage("announcerMaxDepth")
    var announcerMaxDepth: Double = 5

    var body: some View {
        Section {
            Picker("Maximum depth", selection: $announcerMaxDepth) {
                ForEach(Array(stride(from: 1.0, through: 5.0, by: 1.0)), id: \.self) { depth in
                    Text(String(format: "%.0f", depth))
                }
            }
            Picker("Depth interval", selection: $announcerDepthInterval) {
                ForEach([0.25, 0.5, 1.0], id: \.self) { interval in
                    Text(String(format: "%0.2f", interval))
                }
            }
            Picker("Depth margin", selection: $announcerDepthMargin) {
                ForEach(Array(stride(from: 0, through: 0.8, by: 0.1)), id: \.self) { margin in
                    Text(String(format: "%0.1f", margin))
                }
            }
        } header: {
            Text("Announcer Mode")
        } footer: {
            Text(
                "Extends the interval bounds to increase the change in depth required to trigger an announcement."
            )
        }
    }
}

#Preview {
    AnnouncerModeSection()
}
