//
//  SettingsResetSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/25/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct SettingsResetSection: View {
    var body: some View {
        Section {
            Button("Reset to default") {
                UserDefaults.standard.reset()
            }
        }
    }
}
