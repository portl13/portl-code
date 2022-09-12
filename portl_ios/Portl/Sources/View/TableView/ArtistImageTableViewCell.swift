//
//  ArtistImageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 12/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil
import SDWebImage

class ArtistImageTableViewCell: UITableViewCell, FollowButtonProvidingCell, Named {

	// MARK: Configuration
		
	public func configure(withImageURLString imageURLString: String?, name: String, andIsFollowing isFollowing: Bool) {
		if let urlString = imageURLString, let url = URL(string: urlString) {
			artistImageView.sd_setImage(with: url) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.artistImageView.sd_imageIndicator?.stopAnimatingIndicator()
					return
				}
			}
		} else {
			artistImageView.sd_imageIndicator?.stopAnimatingIndicator()
		}
		
		artistNameLabel.attributedText = NSAttributedString(string: name, textStyle: .h2Bold)
		followButton.isSelected = isFollowing
	}
	
	// MARK: FollowButtonProvidingCell
	
	@IBAction func followButtonPressed(_ sender: Any) {
		followButtonDelegate?.followButtonProvidingCellPressedFollowButton(self)
	}
	
	// MARK: Life Cycle
	
	func resetCell() {
		artistImageView.sd_cancelCurrentImageLoad()
		artistImageView.image = nil
		artistImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
				
		artistImageView.sd_imageIndicator = SDWebImageActivityIndicator.white

		resetCell()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		resetCell()
	}
	
	// MARK: Properties
	
	weak var followButtonDelegate: FollowButtonProvidingCellDelegate?

	// MARK: Properties (Private)
	
	@IBOutlet private weak var artistImageView: UIImageView!
	@IBOutlet private weak var artistNameLabel: UILabel!
	@IBOutlet private weak var followButton: FollowButton!
	
	// MARK: Properties (Named)
	
	static var name = "ArtistImageTableViewCell"
}
