//
//  VoteButtonsProviding.swift
//  Portl
//
//  Created by Jeff Creed on 2/6/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import Foundation

protocol VoteButtonsProvidingCell {
	func upvoteButtonPressed(_ sender: Any)
	func downvoteButtonPressed(_ sender: Any)
		
	var voteTotalLabel: UILabel! { get set }
	var upvoteButton: UIButton! { get set }
	var downvoteButton: UIButton! { get set }

	var voteDelegate: VoteButtonsProvidingCellDelegate? { get set }
}

protocol VoteButtonsProvidingCellDelegate: class {
	func voteButtonsProvidingCellSelectedUpvote(_ voteButtonsProvidingCell: VoteButtonsProvidingCell)
	func voteButtonsProvidingCellSelectedDownvote(_ voteButtonsProvidingCell: VoteButtonsProvidingCell)
}
