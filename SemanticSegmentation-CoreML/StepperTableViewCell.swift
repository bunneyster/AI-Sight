//
//  StepperTableViewCell.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 4/1/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import UIKit

class StepperTableViewCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(textField)
        contentView.addSubview(label)
        accessoryView = stepper
        contentView.clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    // MARK: Public

    public func configure(with model: SettingOption) {
        guard case let SettingInput.stepper(input) = model.input else { fatalError() }
        key = model.key
        self.input = input

        textField.text = String(
            format: "%.\(input.precision)f",
            UserDefaults.standard.float(forKey: model.key)
        )
        label.text = model.title
        stepper.value = Double(UserDefaults.standard.float(forKey: model.key))
        stepper.minimumValue = Double(input.min!)
        stepper.maximumValue = Double(input.max!)
        stepper.stepValue = Double(input.stepSize)
    }

    // MARK: Internal

    static let identifier = "StepperTableViewCell"

    override func layoutSubviews() {
        super.layoutSubviews()

        let textFieldSize = String(format: "%.\(input!.precision)f", input!.max!)
            .size(withAttributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)])
        textField.frame = CGRect(
            x: 15,
            y: (contentView.frame.size.height - textFieldSize.height) / 2,
            width: textFieldSize.width + 5,
            height: textFieldSize.height
        )

        label.frame = CGRect(
            x: 15 + textField.frame.size.width + 30,
            y: 0,
            width: contentView.frame.size.width - textField.frame.size.width - 15,
            height: contentView.frame.size.height
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textField.text = nil
        label.text = nil
    }

    @IBAction
    func textEditingEnded(sender: UITextField) {
        if let text = sender.text {
            UserDefaults.standard.set(Float(text), forKey: key!)
        }
        sender.endEditing(false)
    }

    @IBAction
    func step(sender: UIStepper) {
        UserDefaults.standard.set(Float(sender.value), forKey: key!)
        textField.text = String(
            format: "%.\(input!.precision)f",
            UserDefaults.standard.float(forKey: key!)
        )
    }

    // MARK: Private

    private var key: String?
    private var input: RangeSettingInput?

    private lazy var textField: UITextField = { [unowned self] in
        let textField = UITextField()
        textField.keyboardType = .decimalPad
        textField.addTarget(self, action: #selector(textEditingEnded), for: .editingDidEnd)
        return textField
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var stepper: UIStepper = { [unowned self] in
        let stepper = UIStepper()
        stepper.wraps = false
        stepper.autorepeat = true
        stepper.addTarget(self, action: #selector(step), for: .valueChanged)
        return stepper
    }()
}
