//
//  SettingsViewController.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 3/31/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import Foundation
import UIKit

// MARK: - SettingSection

struct SettingSection {
    let title: String
    let options: [SettingOption]
}

// MARK: - SettingOption

struct SettingOption {
    let title: String
    let key: String
    var input: SettingInput
    let handler: () -> Void
}

// MARK: - SettingInput

enum SettingInput {
    case bool
    case stepper(RangeSettingInput)
}

// MARK: - RangeSettingInput

struct RangeSettingInput {
    let min: Float?
    let max: Float?
    let stepSize: Float
    let precision: Int
}

// MARK: - SettingsViewController

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Internal

    let models = [
        SettingSection(title: "General", options: [
            SettingOption(
                title: "Use VoiceOver settings",
                key: "useVoiceOverSettings",
                input: .bool
            ) {},
        ]),
        SettingSection(title: "Scanner Mode", options: [
            SettingOption(
                title: "Rows",
                key: "scannerNumRows",
                input: .stepper(RangeSettingInput(min: 1, max: 20, stepSize: 1, precision: 0))
            ) {},
            SettingOption(
                title: "Columns",
                key: "scannerNumCols",
                input: .stepper(RangeSettingInput(min: 1, max: 20, stepSize: 1, precision: 0))
            ) {},
        ]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.keyboardDismissMode = .onDrag
    }

    func numberOfSections(in _: UITableView) -> Int {
        return models.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].options.count
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = models[section]
        return section.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section].options[indexPath.row]
        switch model.input.self {
        case .bool:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SwitchTableViewCell.identifier,
                for: indexPath
            ) as? SwitchTableViewCell else {
                let defaultCell = UITableViewCell()
                defaultCell.textLabel?.text = model.title
                return defaultCell
            }
            cell.configure(with: model)
            return cell
        case .stepper:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: StepperTableViewCell.identifier,
                for: indexPath
            ) as? StepperTableViewCell else {
                let defaultCell = UITableViewCell()
                defaultCell.textLabel?.text = model.title
                return defaultCell
            }
            cell.configure(with: model)
            return cell
        }
    }

    func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let model = models[indexPath.section].options[indexPath.row]
        switch model.input.self {
        case .bool:
            return indexPath
        case .stepper:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = models[indexPath.section].options[indexPath.row]
        model.handler()
    }

    // MARK: Private

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(
            SwitchTableViewCell.self,
            forCellReuseIdentifier: SwitchTableViewCell.identifier
        )
        table.register(
            StepperTableViewCell.self,
            forCellReuseIdentifier: StepperTableViewCell.identifier
        )
        return table
    }()
}
