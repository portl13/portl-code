//
//  VenueSearchItemTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 5/14/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import Service
import SDWebImage

class VenueSearchItemTableViewCell: UITableViewCell, Named, NibInstantiable {
    
    // MARK: Configuration
    
	func configure(withVenueItem venueItem: VenueKeywordSearchItem, defaultImage: UIImage, source: String, distanceString: String, shouldShowHR: Bool) {
        nameLabel.text = venueItem.venue.name

        // todo: venue objects from server do not have images. is that ok?
        venueImageView.image = defaultImage
        distanceLabel.text = String(format: VenueSearchItemTableViewCell.distanceCityFormat, distanceString)
		hr.isHidden = !shouldShowHR
    }
    
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		venueImageView.layer.cornerRadius = 4
	}

    // MARK: Properties (Named)
    
    static var name = "VenueSearchItemTableViewCell"
    
    // MARK: Properties (Private Static Constant)
    
    // todo: waiting on POR-246
    private static let distanceCityFormat = "%@ miles"
    
    // todo: waiting on POR-246
    private static let addressFormat = "address line 1"
	
    // MARK: Properties (Private)
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var venueImageView: UIImageView!
    @IBOutlet private weak var distanceLabel: UILabel!
	@IBOutlet private weak var hr: UIView!
}
