//
//  AnnouncerModeSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/6/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct AnnouncerModeSection: View {
    @AppStorage("announcerDistanceInterval")
    var announcerDistanceInterval: Double = 0.5

    var body: some View {
        Section(header: Text("Announcer Mode")) {
            Picker("Distance interval", selection: $announcerDistanceInterval) {
                ForEach([0.25, 0.5, 1.0], id: \.self) { interval in
                    Text(String(format: "%0.2f", interval))
                }
            }
        }
    }
}

#Preview {
    AnnouncerModeSection()
}
