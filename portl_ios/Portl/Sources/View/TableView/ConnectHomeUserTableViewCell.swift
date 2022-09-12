//
//  ConnectHomeUserTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 8/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

class ConnectHomeUserTableViewCell: ConnectUserTableViewCell, Named, NibInstantiable  {
	// MARK: Configure
	func configure(withProfileID profileID: String, andConnectButtonStyle buttonStyle: ConnectButtonStyle, showHR: Bool) {
		profile.getProfile(forUserID: profileID) {[unowned self] (firebaseProfile) in
			self.configure(withProfile: firebaseProfile, andConnectButtonStyle: buttonStyle, showHR: showHR)
		}
	}
	
	func configure(withProfile firebaseProfile: Dictionary<String, Any>, andConnectButtonStyle buttonStyle: ConnectButtonStyle, showHR: Bool) {
		spinner.stopAnimating()
		if let imageURL = firebaseProfile[FirebaseKeys.ProfileKeys.avatarKey] as? String {
			profileImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: nil, options: .refreshCached) { (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self.profileImageView.image = self.defaultProfileImage
					self.profileImageView.sd_imageIndicator?.stopAnimatingIndicator()
					return
				}
			}
		} else {
			profileImageView.sd_setImage(with: nil, placeholderImage: defaultProfileImage)
			profileImageView.sd_imageIndicator?.stopAnimatingIndicator()
		}
		
		let fullNameString = (firebaseProfile[FirebaseKeys.ProfileKeys.firstNameKey] as? String ?? "") + " " + (firebaseProfile[FirebaseKeys.ProfileKeys.lastNameKey] as? String ?? "")
		
		usernameLabel.text = firebaseProfile[FirebaseKeys.ProfileKeys.usernameKey] as? String ?? fullNameString
		nameLabel.text = fullNameString
		hr.isHidden = !showHR
		
		
		if let id = firebaseProfile[FirebaseKeys.ProfileKeys.uidKey] as? String, id != Auth.auth().currentUser?.uid {
			configureButtonsForStyle(buttonStyle)
		} else {
			actionButton.isHidden = true
			declineButton.isHidden = true
		}
	}
	
	// MARK: Life Cycle
	
	private func resetCell() {
		profileImageView.sd_cancelCurrentImageLoad()
		profileImageView.image = nil
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		resetCell()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		resetCell()
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		Injector.root!.inject(into: inject)
	}
	
	private func inject(profile: OldProfileService) {
		self.profile = profile
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var usernameLabel: UILabel!
	@IBOutlet private weak var nameLabel: UILabel!
	private var profile: OldProfileService!
	
	// MARK: Properties (Named)
	
	static var name: String = "ConnectHomeUserTableViewCell"
	
	// MARK: Static
	
	static func heightForCell() -> CGFloat {
		return 72.0
	}
}
