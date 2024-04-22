//
//  GeneralSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct GeneralSection: View {
    @AppStorage("useVoiceOverSettings")
    var useVoiceOverSettings: Bool = false

    var body: some View {
        Section(
            header: Text("General"),
            footer: Text("Use the device VoiceOver settings when VoiceOver is enabled.")
        ) {
            Toggle("Use VoiceOver settings", isOn: $useVoiceOverSettings)
        }
    }
}
