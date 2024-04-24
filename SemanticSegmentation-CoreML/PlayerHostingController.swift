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

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
struct PlayerView: View {
    @StateObject
    var manager = CameraManager()

    var body: some View {
        VStack {
            Group {
                if manager.dataAvailable {
                    VideoView(capturedData: manager.capturedData)
                } else {
                    Text("No video data available")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.blue)
                }
            }.frame(width: 400, height: 400)

            PlayerConfigView(manager: manager)

            CameraButtonView(manager: manager)

            Spacer().frame(height: 15)
        }
    }
}

// MARK: - PlayerConfigView

@available(iOS 17.0, *)
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
                Toggle(isOn: $announcer) {
                    Label(
                        title: { Text("Announcer") },
                        icon: { ColorIconView(systemName: "quote.bubble.fill", color: .pink) }
                    )
                }.onChange(of: announcer, initial: true) { _, newValue in
                    newValue ? manager.startAnnouncer() : manager.shutDownAnnouncer()
                }.onChange(of: manager.captureMode) { _, newValue in
                    switch newValue {
                    case .snapshot:
                        manager.shutDownAnnouncer()
                    case .streaming:
                        if announcer {
                            manager.startAnnouncer()
                        }
                    }
                }

                Picker(selection: $scanner) {
                    Text("None").tag("None")
                    Text("People").tag("People")
                    Text("Vehicles").tag("Vehicles")
                    Text("Seating").tag("Seating")
                    Text("Animals").tag("Animals")
                    Text("Bottles").tag("Bottles")
                    Text("TVs").tag("TVs")
                    Text("Tables").tag("Tables")
                    Text("All close objects").tag("All close objects")
                } label: {
                    Label(
                        title: { Text("Scanner") },
                        icon: {
                            ColorIconView(systemName: "field.of.view.wide.fill", color: .orange)
                        }
                    )
                }.onChange(of: scanner, initial: true) { oldValue, newValue in
                    if newValue == "None" {
                        manager.shutDownScanner()
                    } else if oldValue == "None" {
                        manager.startScanner()
                    } else if oldValue == newValue { // View initialization
                        manager.startScanner()
                    }
                }.onChange(of: manager.captureMode) { _, newValue in
                    switch newValue {
                    case .snapshot:
                        manager.shutDownScanner()
                    case .streaming:
                        if scanner != "None" {
                            manager.startScanner()
                        }
                    }
                }

                Picker(selection: $proximity) {
                    Text("None").tag("None")
                    Text("People").tag("People")
                    Text("Vehicles").tag("Vehicles")
                    Text("Seating").tag("Seating")
                    Text("Animals").tag("Animals")
                    Text("Bottles").tag("Bottles")
                    Text("TVs").tag("TVs")
                    Text("Tables").tag("Tables")
                } label: {
                    Label(
                        title: { Text("Proximity") },
                        icon: { ColorIconView(systemName: "sensor.fill", color: .blue) }
                    )
                }.onChange(of: proximity, initial: true) { oldValue, newValue in
                    if newValue == "None" {
                        manager.shutDownObjectProximity()
                    } else if oldValue == "None" {
                        manager.startObjectProximity()
                    } else if oldValue == newValue { // View initialization
                        manager.startObjectProximity()
                    }
                }.onChange(of: manager.captureMode) { _, newValue in
                    switch newValue {
                    case .snapshot:
                        manager.shutDownObjectProximity()
                    case .streaming:
                        if proximity != "None" {
                            manager.startObjectProximity()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ColorIconView

struct ColorIconView: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName).font(.system(size: 12))
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 5).frame(width: 28, height: 28)
                    .foregroundStyle(color)
            )
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
