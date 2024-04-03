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
    @AppStorage("objectProximityThreshold1")
    var objectProximityThreshold1: Double = 0.75
    @AppStorage("objectProximityThreshold2")
    var objectProximityThreshold2: Double = 1.25
    @AppStorage("objectProximityThreshold3")
    var objectProximityThreshold3: Double = 1.75
    @AppStorage("objectProximityThreshold4")
    var objectProximityThreshold4: Double = 2.5

    var body: some View {
        Form {
            Section(
                header: Text("General"),
                footer: Text("Uses the device VoiceOver settings when VoiceOver is enabled.")
            ) {
                Toggle("Use VoiceOver settings", isOn: $useVoiceOverSettings)
            }

            Section(header: Text("Scanner Mode")) {
                let textFieldSize = "888"
                    .size(withAttributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)])
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

            Section(header: Text("Proximity Mode")) {
                HStack {
                    VStack {
                        Text("Threshold 1").font(.subheadline)
                            .multilineTextAlignment(.center)
                        Picker(
                            selection: $objectProximityThreshold1,
                            label: Text("Threshold 1")
                        ) {
                            ForEach(
                                Array(stride(from: 0.5, through: 5, by: 0.25)),
                                id: \.self
                            ) { value in
                                Text(String(format: "%.2f", value)).tag(value)
                            }
                        }.pickerStyle(.wheel)
                    }
                    VStack {
                        Text("Threshold 2").font(.subheadline)
                            .multilineTextAlignment(.center)
                        Picker(
                            selection: $objectProximityThreshold2,
                            label: Text("Threshold 2")
                        ) {
                            ForEach(
                                Array(stride(from: 0.5, through: 5, by: 0.25)),
                                id: \.self
                            ) { value in
                                Text(String(format: "%.2f", value)).tag(value)
                            }
                        }.pickerStyle(.wheel)
                    }
                    VStack {
                        Text("Threshold 3").font(.subheadline)
                            .multilineTextAlignment(.center)
                        Picker(
                            selection: $objectProximityThreshold3,
                            label: Text("Threshold 3")
                        ) {
                            ForEach(
                                Array(stride(from: 0.5, through: 5, by: 0.25)),
                                id: \.self
                            ) { value in
                                Text(String(format: "%.2f", value)).tag(value)
                            }
                        }.pickerStyle(.wheel)
                    }
                    VStack {
                        Text("Threshold 4").font(.subheadline)
                            .multilineTextAlignment(.center)
                        Picker(
                            selection: $objectProximityThreshold4,
                            label: Text("Threshold 4")
                        ) {
                            ForEach(
                                Array(stride(from: 0.5, through: 5, by: 0.25)),
                                id: \.self
                            ) { value in
                                Text(String(format: "%.2f", value)).tag(value)
                            }
                        }.pickerStyle(.wheel)
                    }
                }
            }
        }.navigationTitle("Settings")
    }
}
