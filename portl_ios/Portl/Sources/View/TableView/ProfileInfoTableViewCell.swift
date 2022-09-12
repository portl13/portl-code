//
//  ProfileInfoTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 4/8/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

protocol ProfileInfoTableViewCellDelegate: class {
	func profileInfoTableViewCellSelectedMessage(_ profileInfoTableViewCell: ProfileInfoTableViewCell)
	func profileInfoTableViewCellSelectedEdit(_ profileInfoTableViewCell: ProfileInfoTableViewCell)
	func profileInfoTableViewCellSelectedSettings(_ profileInfoTableViewCell: ProfileInfoTableViewCell)
	func profileInfoTableViewCellSelectedFriends(_ profileInfoTableViewCell: ProfileInfoTableViewCell)
	func profileInfoTableViewCellSelectedWebsite(_ profileInfoTableViewCell: ProfileInfoTableViewCell)
}

class ProfileInfoTableViewCell: UITableViewCell, Named, ConnectEnabledCell {
	func configure(withProfile profile: FirebaseProfile, buttonStyle: ConnectButtonStyle, authorizedID: String?) {
		spinner.stopAnimating()
		let fullName = ([profile.firstName, profile.lastName].compactMap { $0 }).joined(separator: " ")
		nameLabel.text = fullName
		bioLabel.text = profile.bio
		bioLabel.sizeToFit()
		websiteLabel.text = profile.website
		let placeholderImage = UIImage(named: "img_profile_placeholder")!
		
		if let avatarURL = profile.avatar {
			avatarImageView.sd_setImage(with: URL(string: avatarURL), placeholderImage: nil) {[unowned self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self.avatarImageView.image = placeholderImage
					self.avatarImageView.sd_imageIndicator?.stopAnimatingIndicator()
					return
				}
			}
		} else {
			avatarImageView.image = placeholderImage
			avatarImageView.sd_imageIndicator?.stopAnimatingIndicator()
		}
		
		if let eventCount = profile.events?.going?.count {
			eventsLabel.text = "\(eventCount)"
		} else {
			eventsLabel.text = "0"
		}
		
		guard let authorizedID = authorizedID, Auth.auth().currentUser?.isAnonymous != true else {
			buttonsView.isHidden = true
			return
		}
		
		let followingCount = (profile.following?.artist?.count ?? 0) + (profile.following?.venue?.count ?? 0)
		
		followingLabel.text = "\(followingCount)"
		
		if authorizedID != profile.uid {
			configurePublicButtonsForStyle(buttonStyle)
		} else {
			configurePrivateButtons()
		}
	}
	
	
	private func resetButtons() {
		leftButton.isHidden = false
		leftButton.removeTarget(nil, action: nil, for: .allEvents)
		leftButton.setBackgroundImage(nil, for: .normal)
		rightButton.removeTarget(nil, action: nil, for: .allEvents)
		bigMessageButton?.removeFromSuperview()
		buttonsView.isHidden = false
	}
	
	private func configurePrivateButtons() {
		resetButtons()
		leftButton.setBackgroundImage(#imageLiteral(resourceName: "dark_rounded_button_background"), for: .normal)
		leftButton.setTitle("Edit", for: .normal)
		leftButton.addTarget(self, action: #selector(editProfile), for: .touchUpInside)
		rightButton.setTitle("Settings", for: .normal)
		rightButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
	}
	
	private func configurePublicButtonsForStyle(_ style: ConnectButtonStyle) {
		resetButtons()
		
		rightButton.setTitle("Message", for: .normal)
		rightButton.addTarget(self, action: #selector(message), for: .touchUpInside)
		
		switch style {
		case .connected, .sentPending:
			leftButton.backgroundColor = .black
			leftButton.setTitleColor(UIColor(byteValueRed: 204, byteValueGreen: 207, byteValueBlue: 204), for: .normal)
			leftButton.setBackgroundImage(#imageLiteral(resourceName: "dark_rounded_button_background"), for: .normal)
		default:
			leftButton.backgroundColor = .white
			leftButton.setTitleColor(.black, for: .normal)
			leftButton.layer.borderColor = UIColor.white.cgColor
			leftButton.setBackgroundImage(nil, for: .normal)
			leftButton.layer.cornerRadius = 11.0
		}
		
		switch style {
		case .connected:
			leftButton.setTitle("Connected", for: .normal)
			leftButton.addTarget(self, action: #selector(disconnect), for: .touchUpInside)
		case .notConnected:
			leftButton.setTitle("Connect", for: .normal)
			leftButton.addTarget(self, action: #selector(connect), for: .touchUpInside)
		case .receivedPending:
			let bigMessageButton = UIButton(frame: buttonsView.frame)
			bigMessageButton.setTitle("Message", for: .normal)
			bigMessageButton.setTitleColor(UIColor(byteValueRed: 204, byteValueGreen: 207, byteValueBlue: 204), for: .normal)
			bigMessageButton.setBackgroundImage(#imageLiteral(resourceName: "dark_rounded_button_background"), for: .normal)
			bigMessageButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
			bigMessageButton.translatesAutoresizingMaskIntoConstraints = false
			bigMessageButton.addTarget(self, action: #selector(message), for: .touchUpInside)
			
			addSubview(bigMessageButton)
			
			addConstraint(buttonsView.leadingAnchor.constraint(equalTo: bigMessageButton.leadingAnchor))
			addConstraint(buttonsView.topAnchor.constraint(equalTo: bigMessageButton.topAnchor))
			addConstraint(buttonsView.trailingAnchor.constraint(equalTo: bigMessageButton.trailingAnchor))
			addConstraint(buttonsView.bottomAnchor.constraint(equalTo: bigMessageButton.bottomAnchor))
			
			buttonsView.isHidden = true
			
			self.bigMessageButton = bigMessageButton
		case .sentPending:
			leftButton.setTitle("Requested", for: .normal)
			leftButton.addTarget(self, action: #selector(cancelSent), for: .touchUpInside)
		}
		
		layoutIfNeeded()
	}
	
	// MARK: ConnectEnabledCell
	
	@IBAction func connect(_ sender: Any?) {
		leftButton.isHidden = true
		spinner.startAnimating()
		connectDelegate?.connectEnabledCellDidSelectConnect(self)
	}
	
	@IBAction func cancelSent(_ sender: Any?) {
		leftButton.isHidden = true
		spinner.startAnimating()
		connectDelegate?.connectEnabledCellDidSelectCancel(self)
	}
	
	@IBAction func approve(_ sender: Any?) {
		leftButton.isHidden = true
		spinner.startAnimating()
		connectDelegate?.connectEnabledCellDidSelectApprove(self)
	}
	
	@IBAction func disconnect(_ sender: Any?) {
		leftButton.isHidden = true
		spinner.startAnimating()
		connectDelegate?.connectEnabledCellDidSelectDisconnect(self)
	}
	
	@IBAction func decline(_ sender: Any?) {
		leftButton.isHidden = true
		spinner.startAnimating()
		connectDelegate?.connectEnabledCellDidSelectDecline(self)
	}
	
	// MARK: Private (IBAction)
	
	@IBAction private func editProfile(_ sender: Any) {
		delegate?.profileInfoTableViewCellSelectedEdit(self)
	}
	
	@IBAction private func openSettings(_ sender: Any) {
		delegate?.profileInfoTableViewCellSelectedSettings(self)
	}
	
	@IBAction private func message(_ sender: Any) {
		delegate?.profileInfoTableViewCellSelectedMessage(self)
	}
	
	@IBAction private func goToFriends(_ sender: Any) {
		if friendCount > 0 {
			delegate?.profileInfoTableViewCellSelectedFriends(self)
		}
	}
	
	@IBAction private func goToWebsite(_ sender: Any) {
		delegate?.profileInfoTableViewCellSelectedWebsite(self)
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		avatarImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		avatarImageView.sd_imageIndicator?.startAnimatingIndicator()
		
		avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editProfile)))
		avatarImageView.isUserInteractionEnabled = true
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		avatarImageView.sd_cancelCurrentImageLoad()
		avatarImageView.image = nil
		avatarImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Properties
	
	weak var delegate: ProfileInfoTableViewCellDelegate?
	weak var connectDelegate: ConnectEnabledCellDelegate?
	var friendCount: Int = 0 {
		didSet {
			friendsLabel.text = "\(friendCount)"
			friendsLabel.isHidden = false
		}
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var avatarImageView: UIImageView!
	@IBOutlet private weak var nameLabel: UILabel!
	@IBOutlet private weak var bioLabel: UILabel!
	@IBOutlet private weak var websiteLabel: UILabel!
	
	@IBOutlet private weak var buttonsView: UIView!
	@IBOutlet private weak var leftButton: UIButton!
	@IBOutlet private weak var spinner: UIActivityIndicatorView!
	@IBOutlet private weak var rightButton: UIButton!
	
	private var bigMessageButton: UIButton?
	
	@IBOutlet private weak var friendsLabel: UILabel!
	@IBOutlet private weak var friendsButton: UIButton!
	
	@IBOutlet private weak var eventsLabel: UILabel!

	@IBOutlet private weak var followingLabel: UILabel!
	@IBOutlet private weak var followingButton: UIButton!
	
	// MARK: Properties (Private Static Constant)
	
	private static let bioTopMargin: CGFloat = 9.0
	private static let websiteTopMargin: CGFloat = 8.0
	private static let websiteBottomMargin: CGFloat = 15.0
	private static let labelsLeadingMargin: CGFloat = 16.0
	private static let labelsTrailingMargin: CGFloat = 47.0
	private static let minCellHeight: CGFloat = 154.0
	
	// MARK: Properties (Named)
	
	static var name = "ProfileInfoTableViewCell"
	
	// MARK: Static

	static func heightForCell(withWidth width: CGFloat, andProfile profile: FirebaseProfile?) -> CGFloat {
		let constraintRect = CGSize(width: width - labelsLeadingMargin - labelsTrailingMargin, height: .greatestFiniteMagnitude)
		var bioBoundingRect = CGRect()
		var websiteBoundingRect = CGRect()
		var totalHeight = minCellHeight

		if let bio = profile?.bio {
			bioBoundingRect = bio.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0)], context: nil)
			totalHeight += bioTopMargin + bioBoundingRect.size.height
		}

		if let websiteURL = profile?.website {
			websiteBoundingRect = websiteURL.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)], context: nil)
			totalHeight +=  websiteTopMargin + websiteBoundingRect.height + websiteBottomMargin
		}

		return totalHeight
	}
}
