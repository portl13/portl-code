//
//  AttendingUserCollectionViewCell.swift
//  Portl
//
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

class AttendingUserCollectionViewCell: UICollectionViewCell, Named {
	
	// MARK: Configuration
	
	func configure(withProfileID profileID: String) {
		userProfileService.getProfileAvatar(profileID: profileID) {[unowned self] (avatar) in
			if let urlString = avatar, let imageURL = URL(string: urlString) {
				self.profileImageView.sd_setImage(with: imageURL, placeholderImage: nil, options: .refreshCached) { (_, error, _, _) in
					guard error == nil || error!.localizedDescription.contains("2002") else {
						self.profileImageView.image = UIService.defaultProfileImage
						self.profileImageView.sd_imageIndicator?.stopAnimatingIndicator()
						return
					}
				}
			} else {
				self.profileImageView.image = UIService.defaultProfileImage
				self.profileImageView.sd_imageIndicator?.stopAnimatingIndicator()
			}
		}
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(userProfileService: UserProfileService) {
		self.userProfileService = userProfileService
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var profileImageView: UIImageView!
	private var userProfileService: UserProfileService!
	
	// MARK: Properties (Static)
	
	static let cellWidth: CGFloat = 32.0
	
	// MARK: Properties (Named)
	
	static var name: String = "AttendingUserCollectionViewCell"
}
