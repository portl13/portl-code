//
//  EventDetailsCommunityTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/21/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

class EventDetailsCommunityTableViewCell: UITableViewCell, Named {
	
	func configure(withPostsCount postsCount: Int, imagesCount: Int, andCommentsCount commentsCount: Int) {
		postsLabel.attributedText = NSAttributedString(string: String(format: EventDetailsCommunityTableViewCell.postsFormat, postsCount), textStyle: .h3Bold)
		detailsLabel.attributedText = NSAttributedString(string: String(format: EventDetailsCommunityTableViewCell.detailsFormat, imagesCount, commentsCount), textStyle: .body)
		
		let isEmpty = postsCount == 0
		postsLabel.isHidden = isEmpty
		detailsLabel.isHidden = isEmpty
		emptyLabel.isHidden = !isEmpty
		emptyLabelBottomConstraint.constant = isEmpty ? emptyLabelVisibleBottomPadding : emptyLabelDefaultBottomPadding
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		communityLabel.attributedText = UIService.getTableViewHeaderString(forText: EventDetailsCommunityTableViewCell.communityText)
		emptyLabel.attributedText = NSAttributedString(string: EventDetailsCommunityTableViewCell.emptyText, textStyle: .body)
	}
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var postsLabel: UILabel!
	@IBOutlet private weak var detailsLabel: UILabel!
	@IBOutlet private weak var communityLabel: UILabel!
	@IBOutlet private weak var emptyLabel: UILabel!
	@IBOutlet private weak var emptyLabelBottomConstraint: NSLayoutConstraint!
	private let emptyLabelDefaultBottomPadding: CGFloat = 40.0
	private let emptyLabelVisibleBottomPadding: CGFloat = 16.0
	
	// MARK: Properties (Private Static)
	
	private static let communityText = "COMMUNITY"
	private static let postsFormat = "%d Posts"
	private static let detailsFormat = "%d Images • %d Comments"
	private static let emptyText = "Add the first post."
	
	// MARK: Properties (Named)
	
	static let name = "EventDetailsCommunityTableViewCell"
}
