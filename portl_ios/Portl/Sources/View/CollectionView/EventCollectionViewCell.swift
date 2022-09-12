//
//  EventCollectionViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 4/5/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import UIKit
import Service
import SDWebImage

public class EventCollectionViewCell: UICollectionViewCell, Named {
    // MARK: Init
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Injector.root!.inject(into: inject)
		layer.cornerRadius = 4.0
    }
    
    private func inject(formatter: NoTimeDateFormatterQualifier) {
        dateFormatter = formatter.value
    }
    
    // MARK: Cell Life Cycle
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        
        resetCell()
    }
    
    // MARK: Properties (Configure)
    
    func setEventItem(_ eventItem: EventSearchItem?) {
        guard let event = eventItem?.event else {
            resetCell()
            return
        }

        if let distance = eventItem?.distance {
			let distanceString = String(format:"%.1f mi", distance)
			distanceLabel.attributedText = NSAttributedString(string: distanceString, textStyle: .small)
        }

		configureCell(for: event)
    }
    
    @objc func configureForEvent(_ event: PortlEvent, withMeters meters: Double) {
		let distanceString = String(format:"%.1f mi", meters/METERS_ONE_MILE)
		distanceLabel.attributedText = NSAttributedString(string: distanceString, textStyle: .small)
		
		configureCell(for: event)
    }

	private func configureCell(for event: PortlEvent) {
		titleLabel.attributedText = NSAttributedString(string: event.title, textStyle: .bodyBold)
		
		let dateString = dateFormatter.string(from: event.startDateTime as Date)
		dateLabel.attributedText = NSAttributedString(string: dateString, textStyle: .small)
		
		spinner.startAnimating()
		
		if let imageUrl = event.imageURL ?? event.artist?.imageURL, let url = URL(string: imageUrl) {
			imageLoading = true
			backgroundImage.sd_setImage(with: url) {[unowned self] (image, error, _, _) in
				self.imageLoading = false
				self.spinner.stopAnimating()
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self.setDefaultImage(forEvent: event)
					return
				}
			}
		} else {
			spinner.stopAnimating()
			setDefaultImage(forEvent: event)
		}
	}
	
	private func setDefaultImage(forEvent event: PortlEvent) {
		backgroundImage.image = UIService.defaultImageForEvent(event: event)
	}
	
    func resetCell() {
        titleLabel.attributedText = nil
        dateLabel.attributedText = nil
        distanceLabel.attributedText = nil
        backgroundImage.image = nil
        if imageLoading {
            backgroundImage.sd_cancelCurrentImageLoad()
            imageLoading = false
        }
    }
	
    // MARK: Properties (Private)
    
	private var imageLoading = false
    private var dateFormatter: DateFormatter!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var backgroundImage: UIImageView!
	@IBOutlet private weak var spinner: UIActivityIndicatorView!
	
    public static let name = "EventCollectionViewCell"
}
