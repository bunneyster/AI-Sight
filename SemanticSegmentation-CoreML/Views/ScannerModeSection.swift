//
//  ScannerModeSection.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/4/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import SwiftUI

struct ScannerModeSection: View {
    @AppStorage(UserDefaults.Key.scannerBiDirectional.rawValue)
    var scannerBiDirectional: Bool = true
    @AppStorage(UserDefaults.Key.scannerMaxDepth.rawValue)
    var scannerMaxDepth: Double = 2.5
    @AppStorage(UserDefaults.Key.scannerNumRows.rawValue)
    var scannerNumRows: Int = 20
    @AppStorage(UserDefaults.Key.scannerNumColumns.rawValue)
    var scannerNumColumns: Int = 20

    var body: some View {
        Section(header: Text("Scanner Mode")) {
            Toggle("Bidirectional", isOn: $scannerBiDirectional)
            Picker("Maximum depth", selection: $scannerMaxDepth) {
                ForEach(Array(stride(from: 1.0, through: 5.0, by: 0.5)), id: \.self) { depth in
                    Text(String(format: "%.1f", depth))
                }
            }
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
    }
}
