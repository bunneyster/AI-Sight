//
//  SwitchTableViewCell.swift
//  SemanticSegmentation-CoreML
//
//  Created by Staphany Park on 3/31/24.
//  Copyright © 2024 Doyoung Gwak. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(label)
        contentView.clipsToBounds = true
        accessoryView = switchView
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    // MARK: Public

    public func configure(with model: SettingOption) {
        self.model = model

        label.text = model.title
        switchView.isOn = UserDefaults.standard.bool(forKey: model.key)
    }

    // MARK: Internal

    static let identifier = "SwitchTableViewCell"

    override func layoutSubviews() {
        super.layoutSubviews()

        label.frame = CGRect(
            x: 15,
            y: 0,
            width: contentView.frame.size.width - 15,
            height: contentView.frame.size.height
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        switchView.isOn = false
    }

    @IBAction
    func toggle(sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: model!.key)
    }

    // MARK: Private

    private var model: SettingOption?

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var switchView: UISwitch = { [unowned self] in
        let switchView = UISwitch()
        switchView.addTarget(self, action: #selector(toggle), for: .valueChanged)
        return switchView
    }()
}
