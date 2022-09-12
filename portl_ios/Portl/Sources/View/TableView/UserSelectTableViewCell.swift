//
//  UserSelectTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 5/15/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import SDWebImage
import CSkyUtil

class UserSelectTableViewCell: UITableViewCell, Named {
	func configureCell(forProfile profile: Profile) {
		if let imageURLString = profile.avatar {
			profileImageView.sd_setImage(with: URL(string: imageURLString), placeholderImage: nil, options: .refreshCached) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage, options: [], context: nil)
					return
				}
			}
		} else {
			profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage, options: [], context: nil)
		}
		
		usernameLabel.attributedText = NSAttributedString(string: profile.username, textStyle: .h3Bold)
		fullNameLabel.attributedText = NSAttributedString(string: profile.getFirstNameLastName() ?? "", textStyle: .body)
	}
	
	func configureSelectButtonForSelectedState(_ selected: Bool) {
		selectButton.backgroundColor = selected ? PaletteColor.light1.uiColor : PaletteColor.dark1.uiColor
		selectButton.isSelected = selected
	}
	
	func showHR(_ show: Bool) {
		hr.isHidden = !show
	}
	
	func resetCell() {
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		profileImageView.image = nil
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
		usernameLabel.text = nil
		usernameLabel.attributedText = nil
		fullNameLabel.text = nil
		fullNameLabel.attributedText = nil
		configureSelectButtonForSelectedState(false)
	}
	
	// MARK: View Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		selectButton.layer.borderColor = PaletteColor.light1.cgColor
		selectButton.layer.borderWidth = 1.0
		selectButton.layer.cornerRadius = 4.0
		profileImageView.layer.cornerRadius = 20.0
		let defaultText = NSMutableAttributedString(string: UserSelectTableViewCell.selectText, textStyle: .body)
		defaultText.addAttributes([NSAttributedString.Key.foregroundColor : PaletteColor.light1.uiColor], range: NSRange(location: 0, length: defaultText.length))
		let selectedText = NSMutableAttributedString(string: UserSelectTableViewCell.selectedText, textStyle: .body)
		selectedText.addAttributes([NSAttributedString.Key.foregroundColor : PaletteColor.dark1.uiColor], range: NSRange(location: 0, length: selectedText.length))
		selectButton.setAttributedTitle(defaultText, for: .normal)
		selectButton.setAttributedTitle(selectedText, for: .selected)
	}

	// MARK: Properties (Private)
	
	@IBOutlet private weak var profileImageView: UIImageView!
	@IBOutlet private weak var usernameLabel: UILabel!
	@IBOutlet private weak var fullNameLabel: UILabel!
	@IBOutlet private weak var selectButton: UIButton!
	@IBOutlet private weak var hr: UIView!
	
	private static let selectText = "Select"
	private static let selectedText = "Selected"
	
	// MARK: Properties (Named)
	
	static let name = "UserSelectTableViewCell"
}
