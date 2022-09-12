//
//  LivefeedShareTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/28/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift
import SDWebImage
import CoreLocation

class LivefeedShareTableViewCell: UITableViewCell, Named, OverflowMenuProvidingCell {
	func configure(forGoingDataRx goingDataRx: BehaviorSubject<FirebaseProfile.Events.GoingData?>) {
		goingDataDisposable = goingDataRx.subscribe(onNext: {[weak self]  goingData in
			let status = goingData?.goingStatus() ?? .none
			self?.goingSelectedView.isHidden = status != .going
			self?.interestedSelectedView.isHidden = status != .interested
		})
	}
	
	func configure(forPortlEvent portlEvent: PortlEvent?, eventDateFormatter: DateFormatter, myLocation: CLLocation) {
		if let event = portlEvent {
			if let url = UIService.getImageURL(forEvent: event) {
				eventImageView.sd_setImage(with: url) {(_, error, _, _) in
					guard error == nil || error!.localizedDescription.contains("2002") else {
						self.eventImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultImageForEvent(event: event), options: [], context: nil)
						return
					}
				}
			} else {
				eventImageView.sd_setImage(with: nil, placeholderImage:UIService.defaultImageForEvent(event: event), options: [], context: nil)
			}
			
			let distance = myLocation.distance(from: CLLocation(latitude: event.venue.location.latitude, longitude: event.venue.location.longitude)) / 1609.34
			let distanceString = String(format: LivefeedShareTableViewCell.distanceFormat, distance)
			eventDistanceLabel.attributedText = NSAttributedString(string: distanceString, textStyle: .small)
			eventTitleLabel.attributedText = NSAttributedString(string: event.title, textStyle: .bodyBold)
			eventDateLabel.attributedText = NSAttributedString(string: eventDateFormatter.string(from: event.startDateTime as Date), textStyle: .small)
		}
	}
	
	func configure(forConversationOverview conversationOverview: FirebaseConversation.Overview?) {
		if let overview = conversationOverview, let message = overview.firstMessage, !message.isEmpty {
			if overview.commentCount > 0 {
				statsLabel.attributedText = NSAttributedString(string: String(format: LivefeedShareTableViewCell.statsFormat, overview.commentCount) + (overview.commentCount > 1 ? "s" : ""), textStyle: .small)
			} else {
				statsLabel.attributedText = NSAttributedString(string: "Reply", textStyle: .small)
			}
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.lineBreakMode = .byTruncatingTail
			let attrString = NSMutableAttributedString(string: message, textStyle: .h3)
			attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
			commentLabel.attributedText = attrString
		} else {
			statsLabel.attributedText = NSAttributedString(string: "Reply", textStyle: .small)
			commentLabel.attributedText = nil
		}
		layoutIfNeeded()
		statsLabel.isHidden = false
	}
	
	func configure(forProfile profile: FirebaseProfile?) {
		if let urlString = profile?.avatar {
			profileImageView.sd_setImage(with: URL(string: urlString), placeholderImage: nil, options: .refreshCached) {[weak self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self?.profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage)
					return
				}
			}
		} else {
			profileImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultProfileImage)
		}
		
		if let username = profile?.username, let profileID = profile?.uid {
			let isMe = profileID == Auth.auth().currentUser?.uid
			nameToUse = isMe ? "You" : username
			overflowMenuButton.isHidden = !isMe
			
			actionLabel.attributedText = UIService.getActionStringForLivefeed(withProfileName: nameToUse!, isSelf: isMe, eventTitle: nil, andLivefeedActionFormat: .shared)
		}
	}
	
	
	func setActionDateString(_ actionDateString: String) {
		dateLabel.attributedText = NSAttributedString(string: actionDateString, textStyle: .body)
	}
	
	func setShowHR(_ show: Bool) {
		horizontalRule.isHidden = !show
	}
	
	// MARK: OverflowMenuProvidingCell
	
	@IBAction func overflowMenuButtonPressed(_ sender: Any) {
		overflowMenuDelegate?.overflowMenuProvidingCellRequestedMenu(self)
	}
	
	// MARK: Private
	
	@IBAction private func onEventSelected(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedEvent(self)
	}
	
	@IBAction private func onProfileSelected(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedProfile(self)
	}
	
	@IBAction private func onShareDetailSelected(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedShowShareDetail(self)
	}
	
	@IBAction private func onGoingSelected(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedGoing(self)
	}
	
	@IBAction private func onInterestedSelected(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedInterested(self)
	}
	
	private func resetCell() {
		overflowMenuButton.isHidden = true
		eventImageView.sd_cancelCurrentImageLoad()
		eventImageView.image = nil
		eventTitleLabel.text = nil
		eventTitleLabel.attributedText = nil
		eventDateLabel.text = nil
		eventDateLabel.attributedText = nil
		profileImageView.sd_cancelCurrentImageLoad()
		profileImageView.image = nil
		actionLabel.text = nil
		actionLabel.attributedText = nil
		commentLabel.text = nil
		commentLabel.attributedText = nil
		statsLabel.isHidden = true
		if let constraint = commentHeightConstraint {
			commentLabel.removeConstraint(constraint)
			commentHeightConstraint = nil
		}
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	private func determineHeightForComment(comment: String) -> CGFloat {
		let constraintRect = CGSize(width: self.bounds.width - 16.0 - 16.0, height: .greatestFiniteMagnitude)
		return comment.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0)], context: nil).height + 10
	}

	@IBAction private func handleTapOnLabel(_ recognizer: UITapGestureRecognizer) {
		guard let text = actionLabel.attributedText?.string else {
			return
		}
				
		if let nameToUse = nameToUse {
			if let range = text.range(of: nameToUse), recognizer.didTapAttributedTextInLabel(label: actionLabel, inRange: NSRange(range, in: text)) {
				delegate?.livefeedTableViewCellSelectedProfile(self)
			}
		}
	}

	// MARK: Life Cycle
	
	override func awakeFromNib() {
		actionLabel.isUserInteractionEnabled = true
		actionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:))))

		eventImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		
		resetCell()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		resetCell()
		
		eventDisposable?.dispose()
		goingDataDisposable?.dispose()
	}
	
	// MARK: Properties
	
	weak var delegate: LivefeedTableViewCellDelegate?
	weak var overflowMenuDelegate: OverflowMenuProvidingCellDelegate?
	
	// MARK: Properties (Private)
	
	private var nameToUse: String?
	
	private var commentHeightConstraint: NSLayoutConstraint?
	
	private var eventDisposable: Disposable?
	private var goingDataDisposable: Disposable?
	
	private var disposeBag = DisposeBag()
	
	@IBOutlet private weak var profileImageView: UIImageView!
	@IBOutlet private weak var actionLabel: UILabel!
	@IBOutlet private weak var dateLabel: UILabel!
	@IBOutlet private weak var eventImageView: UIImageView!
	@IBOutlet private weak var eventTitleLabel: UILabel!
	@IBOutlet private weak var eventDateLabel: UILabel!
	@IBOutlet private weak var eventDistanceLabel: UILabel!
	@IBOutlet private weak var goingButton: UIButton!
	@IBOutlet private weak var goingSelectedView: UIView!
	@IBOutlet private weak var interestedButton: UIButton!
	@IBOutlet private weak var interestedSelectedView: UIView!
	@IBOutlet private weak var commentLabel: UILabel!
	@IBOutlet private weak var commentBottomConstraint: NSLayoutConstraint! // set to 0 or 16
	@IBOutlet private weak var shareDetailButton: UIButton!
	@IBOutlet private weak var statsLabel: UILabel!
	@IBOutlet private weak var horizontalRule: UIView!
	@IBOutlet private weak var overflowMenuButton: UIButton!
	
	// MARK: Properties (Named)
	
	static let name = "LivefeedShareTableViewCell"
	
	// MARK: Properties (Private Static)
	
	private static let distanceFormat = "%.1f mi"
	private static let statsFormat = "%d Comment"
	//private static let commentBottomConstraintConstant: CGFloat = 16.0
	
}
