//
//  PlayerHostingController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/11/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - PlayerHostingController

class PlayerHostingController: UIHostingController<PlayerView> {
    // MARK: Lifecycle

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: PlayerView())
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - PlayerView

struct PlayerView: View {
    @StateObject
    var manager = CameraManager()

    var body: some View {
        VStack {
            if manager.dataAvailable {
                VideoView(capturedData: manager.capturedData)
            }

            PlayerConfigView(manager: manager)

            CameraButtonView(manager: manager)

            Spacer().frame(height: 15)
        }
    }
}

// MARK: - PlayerConfigView

struct PlayerConfigView: View {
    @ObservedObject
    var manager: CameraManager

    @AppStorage("announcer")
    var announcer: Bool = true
    @AppStorage("scanner")
    var scanner: String = "None"
    @AppStorage("objectProximity")
    var proximity: String = "None"

    var body: some View {
        Form {
            Section {
                Toggle("Announcer", isOn: $announcer)
                    .onChange(of: announcer) { value in
                        value ? manager.startAnnouncer() : manager.shutDownAnnouncer()
                    }
                Picker("Scanner", selection: $scanner) {
                    Text("None").tag("None")
                    Text("People").tag("People")
                    Text("Vehicles").tag("Vehicles")
                    Text("Seating").tag("Seating")
                    Text("Animals").tag("Animals")
                    Text("Bottles").tag("Bottles")
                    Text("TVs").tag("TVs")
                    Text("Tables").tag("Tables")
                    Text("All close objects").tag("All close objects")
                }.onChange(of: scanner) { value in
                    value == "None" ? manager.shutDownScanner() : manager.startScanner()
                }
                Picker("Proximity", selection: $proximity) {
                    Text("None").tag("None")
                    Text("People").tag("People")
                    Text("Vehicles").tag("Vehicles")
                    Text("Seating").tag("Seating")
                    Text("Animals").tag("Animals")
                    Text("Bottles").tag("Bottles")
                    Text("TVs").tag("TVs")
                    Text("Tables").tag("Tables")
                }.onChange(of: proximity) { value in
                    value == "None" ? manager.shutDownObjectProximity() : manager
                        .startObjectProximity()
                }
            }
        }
    }
}

// MARK: - CameraButtonView

struct CameraButtonView: View {
    @ObservedObject
    var manager: CameraManager

    var body: some View {
        Button {
            manager.takePhoto()
        } label: {
            Text("Take Photo")
                .padding(.vertical, 8)
                .padding(.horizontal, 80)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.black)
                .background(.yellow)
                .cornerRadius(8)
        }
    }
}
