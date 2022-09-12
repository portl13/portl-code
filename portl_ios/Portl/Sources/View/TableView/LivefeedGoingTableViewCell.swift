//
//  LivefeedGoingTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import RxSwift
import SDWebImage

class LivefeedGoingTableViewCell: UITableViewCell, Named {
	
	func configure(forPortlEvent portlEvent: PortlEvent?, eventDateFormatter: DateFormatter) {
			if let event = portlEvent {
				if let url = UIService.getImageURL(forEvent: event) {
					eventImageView.sd_setImage(with: url) {[weak self] (_, error, _, _) in
						guard error == nil || error!.localizedDescription.contains("2002") else {
							self?.eventImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultImageForEvent(event: event), options: [], context: nil)
							return
						}
					}
				} else {
					eventImageView.sd_setImage(with: nil, placeholderImage: UIService.defaultImageForEvent(event: event), options: [], context: nil)
				}
				
				eventTitleLabel.attributedText = NSAttributedString(string: event.title, textStyle: .bodyBold)
				eventTitleLabel.heightAnchor.constraint(equalToConstant: determineHeightForEventTitle(title: event.title))
				eventDateLabel.attributedText = NSAttributedString(string: eventDateFormatter.string(from: event.startDateTime as Date), textStyle: .small)
			}
	}
	
	func setShowHR(_ show: Bool) {
		horizontalRule.isHidden = !show
	}
	
	func setActionDateString(_ actionDateString: String) {
		actionDateLabel.attributedText = NSAttributedString(string: actionDateString, textStyle: .body)
	}
	
	func configure(forProfile profile: FirebaseProfile?, goingStatus: FirebaseProfile.EventGoingStatus) {
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
		
		if let username = profile?.username, let uid = profile?.uid {
			actionLabel.attributedText = getActionString(forProfileID: uid, username: username, andGoingStatus: goingStatus)
		}

	}

	// MARK: Private
	
	private func determineHeightForEventTitle(title: String) -> CGFloat {
		let constraintRect = CGSize(width: self.bounds.width - 8.0 - eventImageView.bounds.width - 16.0 - 16.0 - profileImageView.bounds.width - 16.0, height: .greatestFiniteMagnitude)
		let rect = NSAttributedString(string: title, textStyle: .bodyBold).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
		return rect.height
	}
	
	func getActionString(forProfileID profileID: String, username: String, andGoingStatus goingStatus: FirebaseProfile.EventGoingStatus) -> NSAttributedString? {
		let format = goingStatus == .interested ? LivefeedActionFormat.interested : LivefeedActionFormat.going
		if Auth.auth().currentUser?.uid == profileID {
			nameToUse = "You"
			return UIService.getActionStringForLivefeed(withProfileName: "You", isSelf: true, eventTitle: nil, andLivefeedActionFormat: format)
		} else {
			nameToUse = username
			return UIService.getActionStringForLivefeed(withProfileName: username, isSelf: false, eventTitle: nil, andLivefeedActionFormat: format)
		}
	}
	
	@IBAction private func onProfileSelected(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedProfile(self)
	}
	
	@IBAction private func onEventSelected(_ sender: Any) {
		delegate?.livefeedTableViewCellSelectedEvent(self)
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

	private func resetCell() {
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
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
		eventImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		eventImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		eventImageView.layer.cornerRadius = 4
		resetCell()
		
		actionLabel.isUserInteractionEnabled = true
		actionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:))))
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		resetCell()
		eventDisposable?.dispose()
	}
	
	// MARK: Properties
	
	weak var delegate: LivefeedTableViewCellDelegate?
	
	// MARK: Properties (Private)
	
	private var nameToUse: String?
	
	private var eventDisposable: Disposable?
	
	@IBOutlet private weak var profileImageView: UIImageView!
	@IBOutlet private weak var actionLabel: UILabel!
	@IBOutlet private weak var actionDateLabel: UILabel!
	@IBOutlet private weak var eventImageView: UIImageView!
	@IBOutlet private weak var eventTitleLabel: UILabel!
	@IBOutlet private weak var eventDateLabel: UILabel!
	@IBOutlet private weak var horizontalRule: UIView!
	
	// MARK: Properties (Named)
	
	static let name = "LivefeedGoingTableViewCell"
		
}
