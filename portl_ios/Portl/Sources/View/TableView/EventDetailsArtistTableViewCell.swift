//
//  EventDetailsArtistTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/22/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

protocol EventDetailsAttendeesTableViewCellDelegate: class {
	func attendingUsersTableViewCell(_ attendingUsersTableViewCell: EventDetailsAttendeesTableViewCell, didSelectUserWithProfileID profileID: String)
}

class EventDetailsArtistTableViewCell: UITableViewCell, Named {
	
	func configure(withArtistImageURL artistImageURL: String?, fallbackImage: UIImage, artistName: String, upcomingEventCount: Int, recentEventCount: Int) {
		if let urlString = artistImageURL, let url = URL(string: urlString) {
			artistImageView.sd_setImage(with: url) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.artistImageView.image = fallbackImage
					self?.artistImageView.sd_imageIndicator?.stopAnimatingIndicator()
					return
				}
			}
		} else {
			artistImageView.image = fallbackImage
			artistImageView.sd_imageIndicator?.stopAnimatingIndicator()
		}
		nameLabel.attributedText = NSAttributedString(string: artistName, textStyle: .h3Bold)
		upcomingLabel.attributedText = NSAttributedString(string: String(format: EventDetailsArtistTableViewCell.upcomingFormat, upcomingEventCount), textStyle: .body)
	}

	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		artistLabel.attributedText = UIService.getTableViewHeaderString(forText: EventDetailsArtistTableViewCell.artistText)
		artistImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		artistImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		artistImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var artistLabel: UILabel!
	@IBOutlet private weak var artistImageView: UIImageView!
	@IBOutlet private weak var nameLabel: UILabel!
	@IBOutlet private weak var upcomingLabel: UILabel!
	
	// MARK: Properties (Private Static)
	
	private static let artistText = "ARTIST"
	private static let upcomingFormat = "%d upcoming events"
	
	// MARK: Properties (Named)
	
	static let name = "EventDetailsArtistTableViewCell"
}
