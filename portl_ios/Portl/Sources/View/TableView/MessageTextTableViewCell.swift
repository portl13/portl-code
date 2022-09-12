//
//  MessageTextTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

protocol MessageTextTableViewCellDelegate: class {
	func messageTextTableViewCell(_ messageTextTableViewCell: MessageTextTableViewCell, didSetText text: String?)
}

class MessageTextTableViewCell: UITableViewCell, Named, UITextFieldDelegate {
	
	// MARK: UITextFieldDelegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
	
	// MARK: Private
	
	@IBAction func textFieldDidChange(_ textField: UITextField) {
		delegate?.messageTextTableViewCell(self, didSetText: textField.text)
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
		
		textFieldBorder.layer.borderColor = PaletteColor.dark3.cgColor
		textFieldBorder.layer.borderWidth = 1
		textFieldBorder.layer.cornerRadius = 8
		textField.placeholder = MessageTextTableViewCell.placeholderText
		textField.attributedPlaceholder = NSAttributedString(string: MessageTextTableViewCell.placeholderText, textStyle: .h3)
	}
	
	// MARK: Properties
	
	var messageText: String? {
		get {
			return textField.text
		}
		set {
			textField.text = newValue
		}
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var textFieldBorder: UIView!
	@IBOutlet private weak var textField: UITextField!
	weak var delegate: MessageTextTableViewCellDelegate?
	
	// MARK: Properties (Private Static)
	
	private static let placeholderText = "Enter your comment..."
	
	// MARK: Properties (Named)
	
	static let name = "MessageTextTableViewCell"
	
	// MARK: Enum
	
	enum messageType {
		case community
		case direct
	}
}
