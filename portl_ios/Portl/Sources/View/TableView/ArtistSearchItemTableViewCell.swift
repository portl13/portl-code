//
//  ArtistSearchItemTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 5/14/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import Service
import SDWebImage

class ArtistSearchItemTableViewCell: UITableViewCell, Named, NibInstantiable {
    
    // MARK: Configuration
    
	func configure(withArtistItem artistItem: ArtistKeywordSearchItem, defaultImage: UIImage, source: String, shouldShowHR: Bool) {
        nameLabel.text = artistItem.artist.name
        if let imageURL = artistItem.artist.imageURL {
            artistImageView.sd_setImage(with: URL(string: imageURL), completed: { [unowned self] (image: UIImage?, error: Error?, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
                    self.artistImageView.image = defaultImage
                    return
                }
            })
        } else {
            artistImageView.image = defaultImage
        }
        
        // todo: we built the api to send the events with the artist, but all we need for the search query is the counts. should we change the api to not send the events with the search response?
        
        let now = Date()
        let pastEvents = (artistItem.events as! Set<PortlEvent>).filter { (event) -> Bool in
            return (event.startDateTime as Date) < now
        }
        let upcomingEvents = (artistItem.events as! Set<PortlEvent>).filter { (event: PortlEvent) -> Bool in
            return (event.startDateTime as Date) >= now
        }
        
        upcomingLabel.text = String(format: ArtistSearchItemTableViewCell.upcomingFormat, arguments: [(upcomingEvents.count > 0 ? "\(upcomingEvents.count)" : "no")])
        pastLabel.text = String(format: ArtistSearchItemTableViewCell.pastFormat, arguments: [(pastEvents.count > 0 ? "\(pastEvents.count)" : "no")])
		hr.isHidden = !shouldShowHR
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		artistImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		artistImageView.layer.cornerRadius = 4
	}
    
    // MARK: Properties (Named)
    
    static var name = "ArtistSearchItemTableViewCell"
    
    // MARK: Properties (Private Static Constant)
    
    private static let upcomingFormat = "%@ upcoming events"
    private static let pastFormat = "%@ recent events"
	
    // MARK: Properties (Private)
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var artistImageView: UIImageView!
    @IBOutlet private weak var upcomingLabel: UILabel!
    @IBOutlet private weak var pastLabel: UILabel!
	@IBOutlet private weak var hr: UIView!
}
