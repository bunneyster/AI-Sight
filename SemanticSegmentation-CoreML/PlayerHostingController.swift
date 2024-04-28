//
//  PlayerHostingController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/11/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation
import OSLog
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

            PlayerConfig()

            CameraButton()

            Spacer().frame(height: 15)
        }.onAppear {
            manager.resume()
        }.onDisappear {
            manager.pause()
        }.environmentObject(manager)
    }
}

// MARK: - PlayerConfig

@available(iOS 17.0, *)
struct PlayerConfig: View {
    @EnvironmentObject
    var manager: CameraManager

    @AppStorage(UserDefaults.Key.announcer.rawValue)
    var announcer: Bool = true
    @AppStorage(UserDefaults.Key.scanner.rawValue)
    var scanner: String = "None"
    @AppStorage(UserDefaults.Key.proximeter.rawValue)
    var proximeter: String = "None"

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $announcer) {
                    Label(
                        title: { Text("Announcer") },
                        icon: { ColorIcon(systemName: "quote.bubble.fill", color: .pink) }
                    )
                }.onChange(of: announcer, initial: true) { _, newValue in
                    newValue ? manager.connectAnnouncer() : manager.disconnectAnnouncer()
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
                            ColorIcon(systemName: "field.of.view.wide.fill", color: .orange)
                        }
                    )
                }.onChange(of: scanner, initial: true) { oldValue, newValue in
                    if newValue == "None" {
                        manager.disconnectScanner()
                    } else if oldValue == "None" {
                        manager.connectScanner()
                    } else if oldValue == newValue { // View initialization
                        manager.connectScanner()
                    }
                }

                Picker(selection: $proximeter) {
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
                        icon: { ColorIcon(systemName: "sensor.fill", color: .blue) }
                    )
                }.onChange(of: proximeter, initial: true) { oldValue, newValue in
                    if newValue == "None" {
                        manager.disconnectProximeter()
                    } else if oldValue == "None" {
                        manager.connectProximeter()
                    } else if oldValue == newValue { // View initialization
                        manager.connectProximeter()
                    }
                }
            }
        }
    }
}

// MARK: - ColorIcon

struct ColorIcon: View {
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

// MARK: - CameraButton

struct CameraButton: View {
    @EnvironmentObject
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
