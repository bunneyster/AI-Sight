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
    var body: some View {
        Form {
            GeneralSection()

            ObjectPropertiesSection()

            ObjectDepthSection()

            ScannerModeSection()

            ProximityModeSection()
        }.navigationTitle("Settings")
    }
}
