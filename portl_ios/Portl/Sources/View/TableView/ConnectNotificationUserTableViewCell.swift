//
//  ConnectNotificationUserTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 8/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

class ConnectNotificationUserTableViewCell: ConnectUserTableViewCell, Named, NibInstantiable {
	// Mark: Configure
	
	func configure(withImageURL imageURL: String?, name: String, dateString: String, andConnectButtonStyle buttonStyle: ConnectButtonStyle, showHR: Bool) {
		spinner.stopAnimating()
		if let imageURL = imageURL {
			profileImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: nil, options: .refreshCached) { (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self.profileImageView.image = self.defaultProfileImage
					self.profileImageView.sd_imageIndicator?.stopAnimatingIndicator()
					return
				}
			}
		} else {
			profileImageView.sd_setImage(with: nil, placeholderImage: defaultProfileImage)
		}
		
		notificationLabel.attributedText = ConnectNotificationUserTableViewCell.buildNotificationString(forNameString: name, andButtonStyle: buttonStyle)
		hr.isHidden = !showHR
		configureButtonsForStyle(buttonStyle)
		timeLabel.text = dateString
	}
	
	// MARK: Private
	
	private func resetCell() {
		profileImageView.sd_cancelCurrentImageLoad()
		profileImageView.image = nil
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		resetCell()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		resetCell()
	}

	// MARK: Properties (Private)
	
	@IBOutlet weak var notificationLabel: UILabel!
	@IBOutlet private weak var timeLabel: UILabel!
	
	// MARK: Properties (Named)
	
	static var name: String = "ConnectNotificationUserTableViewCell"
	
	// MARK: Properties (Static Const)
	
	private static let notificationTopMargin: CGFloat = 16.0
	private static let notificationLeftMargin: CGFloat = 64.0
	private static let notificationRightMargin: CGFloat = 16.0
	private static let buttonsRightMargin: CGFloat = 16.0
	private static let buttonHeight: CGFloat = 37.0
	private static let timeHeightPlusTopBottom: CGFloat = 32.0 + 15.0
	private static let hrHeight: CGFloat = 1.0
	
	// MARK: Static

	static func buildNotificationString(forNameString nameString: String, andButtonStyle buttonStyle: ConnectButtonStyle) -> NSAttributedString {
		var text = ""
		switch buttonStyle {
		case .connected:
			text = "You are now friends with \(nameString)."
		case .receivedPending:
			text = "\(nameString) sent you a friend request."
		case .sentPending:
			text = "You've invited \(nameString) to be friends."
		default:
			text = ""
		}
		
		let attributedText = NSMutableAttributedString(string: text, attributes: [.font : UIFont.systemFont(ofSize: 16), .foregroundColor : UIColor(byteValueRed: 204, byteValueGreen: 207, byteValueBlue: 204)])
		if let nameRange = text.range(of: nameString) {
			attributedText.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(nameRange, in: text))
		}
		return attributedText
	}

	private static func buttonWidthForButtonStyle(_ style: ConnectButtonStyle) -> CGFloat {
		switch style {
		case .connected:
			return 101.0
		case .notConnected:
			return 81.0
		case .receivedPending:
			return 80.0 + 16.0 + 24.0
		case .sentPending:
			return 101.0
		}
	}
	
	static func heightForCell(withWidth width: CGFloat, message: NSAttributedString, buttonStyle: ConnectButtonStyle) -> CGFloat {
		var textHeight: CGFloat = 0.0
		let constraintRect = CGSize(width: width - notificationLeftMargin - notificationRightMargin - buttonWidthForButtonStyle(buttonStyle) - buttonsRightMargin, height: .greatestFiniteMagnitude)
		textHeight += message.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil).height
		
		return message.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil).height + notificationTopMargin + timeHeightPlusTopBottom + hrHeight + 1
	}
}
