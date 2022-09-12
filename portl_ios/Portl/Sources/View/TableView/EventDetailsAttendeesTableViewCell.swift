//
//  EventDetailsAttendeesTableViewCell.swift
//  Portl
//
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil

class EventDetailsAttendeesTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate, Named {
	
	// MARK: UICollectionViewDataSource
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return profileIDs.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeue(AttendingUserCollectionViewCell.self, for: indexPath)
		cell.configure(withProfileID: profileIDs[indexPath.row])
		
		return cell
	}
	
	// MARK: UICollectionViewDelegate
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: false)
		if allowProfileSegue {
			let profileID = profileIDs[indexPath.row]
			delegate?.attendingUsersTableViewCell(self, didSelectUserWithProfileID: profileID)
		}
	}
	
	// MARK: Configuration
	
	@objc func configure(withProfileIDs profileIDs: Array<String>, goingCount: Int, interestedCount: Int, allowProfileSegue: Bool = false) {
		let maxProfiles = Int(collectionView.frame.size.width / AttendingUserCollectionViewCell.cellWidth)
		self.profileIDs = Array(profileIDs.dropLast(max(0, profileIDs.count - maxProfiles)))
		self.allowProfileSegue = allowProfileSegue
		countsLabel.attributedText = NSAttributedString(string: String(format: EventDetailsAttendeesTableViewCell.countsFormat, goingCount, interestedCount), textStyle: .h3Bold)
		
		let isEmpty = profileIDs.count == 0
		collectionView.isHidden = isEmpty
		countsLabel.isHidden = isEmpty
		emptyLabelBottomConstraint.constant = isEmpty ? emptyLabelVisibleBottomPadding : emptyLabelDefaultBottomPadding
		emptyStateLabel.isHidden = !isEmpty
		collectionView.reloadData()
		setNeedsLayout()
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		attendeesLabel.attributedText = UIService.getTableViewHeaderString(forText: EventDetailsAttendeesTableViewCell.attendeesText)
		emptyStateLabel.attributedText = NSAttributedString(string: EventDetailsAttendeesTableViewCell.emptyText, textStyle: .body)
		
		collectionView.registerNib(AttendingUserCollectionViewCell.self)
	}
	
	// MARK: Properties
	
	var delegate: EventDetailsAttendeesTableViewCellDelegate?
	
	// MARK: Properties (Private)
	
	private var profileIDs = Array<String>()
	private var allowProfileSegue: Bool = false

	@IBOutlet private weak var collectionView: UICollectionView!
	@IBOutlet private weak var attendeesLabel: UILabel!
	@IBOutlet private weak var countsLabel: UILabel!
	@IBOutlet private weak var emptyLabelBottomConstraint: NSLayoutConstraint!
	@IBOutlet private weak var emptyStateLabel: UILabel!
	private let emptyLabelDefaultBottomPadding: CGFloat = 59.5
	private let emptyLabelVisibleBottomPadding: CGFloat = 16.0

	// MARK: Properties (Private Static)
	
	private static let countsFormat = "%d Going • %d Interested"
	private static let attendeesText = "ATTENDEES"
	private static let emptyText = "Be the first attendee."
	private static let countsHeight: CGFloat = 24.0
	private static let defaultPadding: CGFloat = 16.0
	
	// MARK: Properties (Named)
	
	static let name = "EventDetailsAttendeesTableViewCell"
}

