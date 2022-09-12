//
//  EventMapAnnotationView.swift
//  Portl
//
//  Created by Jeff Creed on 4/13/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import MapKit
import Service
import CSkyUtil
import SDWebImage

class EventCalloutView: UIView, Named, NibInstantiable {
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Injector.root!.inject(into: inject)
    }
    
    private func inject(formatter: DateFormatterQualifier) {
        dateFormatter = formatter.value
    }
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		imageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		imageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
    // MARK: Properties
    
    func setEventSearchItem(eventSearchItem: EventSearchItem?) {        
        let category: String? = (eventSearchItem?.event.categories.sortedArray(using: [NSSortDescriptor(key: "orderIndex", ascending: true)]).first as? EventCategory)?.name
        
        if category == nil {
            categoryLabel.isHidden = true
        } else {
            categoryLabel.text = category
            categoryLabel.isHidden = false
        }
        
		let placeholder = UIService.defaultImageForEvent(event: eventSearchItem!.event)
        if let imageUrl = eventSearchItem?.event.imageURL ?? eventSearchItem?.event.artist?.imageURL {
			imageView.sd_setImage(with: URL(string: imageUrl)) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.imageView.image = placeholder
					self?.imageView.sd_imageIndicator?.stopAnimatingIndicator()
					return
				}
			}
        } else {
            imageView.image = placeholder
			imageView.sd_imageIndicator?.stopAnimatingIndicator()
        }
        
        titleLabel.text = eventSearchItem?.event.title ?? ""
        
        artistLabel.text = eventSearchItem?.event.artist?.name ?? ""
        if let date = eventSearchItem?.event.startDateTime {
            startDateLabel.text = dateFormatter.string(from: date as Date)
        } else {
            startDateLabel.text = ""
        }

		if let distance = eventSearchItem?.distance {
            distanceLabel.text = String(format:"%.1f mi", distance)
        }
    }
    
    @IBAction private func triggerDetailSegue() {
        delegate?.calloutViewButtonPressed()
    }
    
    // MARK: Properties
    
    weak var delegate: EventCalloutViewDelegate?
    
    // MARK: Properties (Private)
    
    private var dateFormatter: DateFormatter!
    private var uiService: UIService!
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var startDateLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var categoryLabel: UILabel!
    
    // MARK: Properties (Named)
    
    static var name: String = "EventCalloutView"
}
