//
//  SettingsHostingController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/2/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - SettingsHostingController

class SettingsHostingController: UIHostingController<SettingsView> {
    // MARK: Lifecycle

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SettingsView())
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @AppStorage("useVoiceOverSettings")
    var useVoiceOverSettings: Bool = false
    @AppStorage("scannerNumRows")
    var scannerNumRows: Int = 20
    @AppStorage("scannerNumColumns")
    var scannerNumColumns: Int = 20

    var body: some View {
        Form {
            Section(
                header: Text("General"),
                footer: Text("Uses the device VoiceOver settings when VoiceOver is enabled.")
            ) {
                Toggle("Use VoiceOver settings", isOn: $useVoiceOverSettings)
            }
            Section(header: Text("Scanner Mode")) {
                let textFieldSize = "888".size(withAttributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)])
                HStack {
                    TextField("", value: $scannerNumRows, formatter: NumberFormatter())
                        .frame(width: textFieldSize.width)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Rows")
                    Stepper(value: $scannerNumRows, in: 1...20, step: 1) {
                        Text("Rows").foregroundStyle(.secondary)
                    }
                }
                HStack {
                    TextField("", value: $scannerNumColumns, formatter: NumberFormatter())
                        .frame(width: textFieldSize.width)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Columns")
                    Stepper(value: $scannerNumColumns, in: 1...20, step: 1) {
                        Text("Columns").foregroundStyle(.secondary)
                    }
                }
            }
        }.navigationTitle("Settings")
    }
}
