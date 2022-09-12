//
//  EventDetailsActionTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/13/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

protocol EventDetailsActionTableViewCellDelegate: class {
	func eventActionTableViewCellDidSelectGoing(_ eventActionTableViewCell: EventDetailsActionTableViewCell)
	func eventActionTableViewCellDidSelectInterested(_ eventActionTableViewCell: EventDetailsActionTableViewCell)
	func eventActionTableViewCellDidSelectBookmark(_ eventActionTableViewCell: EventDetailsActionTableViewCell)
	func eventActionTableViewCellDidSelectDirections(_ eventActionTableViewCell: EventDetailsActionTableViewCell)
	func eventActionTableViewCell(_ eventActionTableViewCell: EventDetailsActionTableViewCell, requestsOpenExternalURL URL: URL)
}

class EventDetailsActionTableViewCell: UITableViewCell, Named {
	// MARK: Config
	
	func configure(withGoingStatus status:FirebaseProfile.EventGoingStatus, isBookmarked: Bool, ticketURLString: String?, infoURLString: String?) {
		goingSelectedView.isHidden = status != .going
		interestedSelectedView.isHidden = status != .interested
		
		ticketsOrInfoLabel.isHidden = ticketURLString == nil && infoURLString == nil
		if let URLString = ticketURLString {
			ticketsOrInfoButton.setImage(UIImage(named: "icon_action_tickets"), for: .normal)
			ticketsOrInfoLabel.attributedText = NSAttributedString(string: EventDetailsActionTableViewCell.ticketsLabelText, textStyle: .small)
			externalURL = URL(string: URLString)
		} else if let URLString = infoURLString {
			ticketsOrInfoButton.setImage(UIImage(named: "icon_action_more_info"), for: .normal)
			ticketsOrInfoLabel.attributedText = NSAttributedString(string: EventDetailsActionTableViewCell.moreInfoLabelText, textStyle: .small)
			externalURL = URL(string: URLString)
		} else {
			externalURL = nil
		}
		
		if isBookmarked {
			bookmarkButton.setImage(UIImage(named: "icon_action_bookmark_selected"), for: .normal)
		} else {
			bookmarkButton.setImage(UIImage(named: "icon_action_bookmark"), for: .normal)
		}
	}
	
	// MARK: Private
	
	@IBAction private func onGoingSelected(_ sender: Any) {
		delegate?.eventActionTableViewCellDidSelectGoing(self)
	}
	
	@IBAction private func onInterestedSelected(_ sender: Any) {
		delegate?.eventActionTableViewCellDidSelectInterested(self)
	}
	
	@IBAction private func onBookmarkSelected(_ sender: Any) {
		delegate?.eventActionTableViewCellDidSelectBookmark(self)
	}
	
	@IBAction private func onDirectionsSelected(_ sender: Any) {
		delegate?.eventActionTableViewCellDidSelectDirections(self)
	}
	
	@IBAction private func onTicketsOrInfoSelected(_ sender: Any) {
		guard externalURL != nil else {
			return
		}
		delegate?.eventActionTableViewCell(self, requestsOpenExternalURL: externalURL!)
	}
	
	// MARK: View Life Cycle
	
	override func awakeFromNib() {
		goingLabel.attributedText = NSAttributedString(string: EventDetailsActionTableViewCell.goingLabelText, textStyle: .small)
		interestedLabel.attributedText = NSAttributedString(string: EventDetailsActionTableViewCell.interestedLabelText, textStyle: .small)
		bookmarkLabel.attributedText = NSAttributedString(string: EventDetailsActionTableViewCell.bookmarkLabelText, textStyle: .small)
		directionsLabel.attributedText = NSAttributedString(string: EventDetailsActionTableViewCell.directionsLabelText, textStyle: .small)
	}
	
	// MARK: Properties
	
	weak var delegate: EventDetailsActionTableViewCellDelegate?
	
	// MARK: Properties (Named)
	
	static var name = "EventDetailsActionTableViewCell"

	// MARK: Properties (Private)
	
	private var externalURL: URL?
	
	@IBOutlet private weak var goingSelectedView: UIView!
	@IBOutlet private weak var interestedSelectedView: UIView!
	@IBOutlet private weak var bookmarkButton: UIButton!
	@IBOutlet private weak var ticketsOrInfoButton: UIButton!
	
	@IBOutlet private weak var goingLabel: UILabel!
	@IBOutlet private weak var interestedLabel: UILabel!
	@IBOutlet private weak var bookmarkLabel: UILabel!
	@IBOutlet private weak var directionsLabel: UILabel!
	@IBOutlet private weak var ticketsOrInfoLabel: UILabel!
	
	// MARK: Properties (Private Static)
	
	private static let goingLabelText = "Going"
	private static let interestedLabelText = "Interested"
	private static let bookmarkLabelText = "Bookmark"
	private static let directionsLabelText = "Directions"
	private static let ticketsLabelText = "Tickets"
	private static let moreInfoLabelText = "More Info"
}
