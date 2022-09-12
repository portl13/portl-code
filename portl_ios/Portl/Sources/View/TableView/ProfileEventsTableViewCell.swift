//
//  ProfileEventsTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 4/8/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Service
import CoreData
import CSkyUtil

protocol ProfileEventsTableViewCellDelegate: class {
	func profileEventsTableViewCell(_ profileEventsTableViewCell: ProfileEventsTableViewCell, didSelectEvent event: PortlEvent)
}

class ProfileEventsTableViewCell: UITableViewCell, Named, ProfileEventControllerDelegate {
	override func awakeFromNib() {
		super.awakeFromNib()
		eventCollectionView.contentInset = UIEdgeInsets(top: 0.0, left: ProfileEventsTableViewCell.collectionViewLeftInset, bottom: 0.0, right: 0.0)
	}
	
	// MARK: SearchControllerDelegate
	
	func initiateEventDetailTransition(withEvent event:PortlEvent) {
		delegate?.profileEventsTableViewCell(self, didSelectEvent: event)
	}
	
	// MARK: Properties (Configure)
	
	func configureWith(eventsController: ProfileEventsController?, emptyMessage: String? = nil) {		
		if let emptyMessage = emptyMessage {
			noEventsLabel.attributedText = NSAttributedString(string: emptyMessage, textStyle: .body)
		}
		
		if let eventController = eventsController {
			eventController.collectionView = eventCollectionView
			eventController.delegate = self
			
			activityIndicator.stopAnimating()
			noEventsLabel.isHidden = eventController.hasItems
		}
		else {
			eventCollectionView.dataSource = nil
			eventCollectionView.delegate = nil
			eventCollectionView.reloadData()
			
			activityIndicator.startAnimating()
		}
	}
	
	// MARK: Properties
	
	weak var delegate: ProfileEventsTableViewCellDelegate?
	
	// MARK: Properties (Private)
		
	@IBOutlet private weak var noEventsLabel: UILabel!
	@IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet private weak var eventCollectionView: UICollectionView!
	
	// MARK: Properties (Private Static Constant)
	
	private static let collectionViewLeftInset: CGFloat = 16.0
	
	// MARK: Properties (Named)
	
	public static let name = "ProfileEventsTableViewCell"
}

