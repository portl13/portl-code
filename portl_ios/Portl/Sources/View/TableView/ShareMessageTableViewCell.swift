//
//  ShareMessageTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 3/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import RxSwift
import CSkyUtil

protocol ShareMessageTableViewCellDelegate: class {
	func shareMessageTableViewCellSelectedProfile(_ shareMessageTableViewCell: ShareMessageTableViewCell)
}

class ShareMessageTableViewCell: UITableViewCell, Named {
	
	func configure(forMessage message: String, profileRx: BehaviorSubject<FirebaseProfile?>) {
		profileDisposable = profileRx.subscribe(onNext: {[weak self] profile in
			if let strongSelf = self, let profile = profile {
				let isMe = Auth.auth().currentUser?.uid == profile.uid
				strongSelf.nameToUse = isMe ? "You" : profile.username
				let string = NSMutableAttributedString(string: "\(strongSelf.nameToUse!)  \(message)")
				string.setTextStyle(.bodyBold, range: NSRange(location: 0, length: strongSelf.nameToUse!.count))
				string.setTextStyle(.body, range: NSRange(location: strongSelf.nameToUse!.count, length: string.length - strongSelf.nameToUse!.count))
				string.setAttributes([NSAttributedString.Key.foregroundColor : PaletteColor.light2.uiColor], range:  NSRange(location: strongSelf.nameToUse!.count, length: string.length - strongSelf.nameToUse!.count))
				strongSelf.messageLabel.attributedText = string
				DispatchQueue.main.async {
					strongSelf.messageLabel.isHidden = false
					strongSelf.setNeedsLayout()
				}
			}
		})
	}
	
	// MARK: Private
	
	@IBAction private func handleTapOnLabel(_ recognizer: UITapGestureRecognizer) {
		guard let text = messageLabel.attributedText?.string else {
			return
		}
				
		if let nameToUse = nameToUse {
			if let range = text.range(of: nameToUse), recognizer.didTapAttributedTextInLabel(label: messageLabel, inRange: NSRange(range, in: text)) {
				delegate?.shareMessageTableViewCellSelectedProfile(self)
			}
		}
	}
	
	// MARK: Life Cycle
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		profileDisposable?.dispose()
		messageLabel.isHidden = true
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		messageLabel.isUserInteractionEnabled = true
		messageLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:))))
	}
	
	// MARK: Properties
	
	weak var delegate: ShareMessageTableViewCellDelegate?
	
	// MARK: Properties (Private)
	
	private var nameToUse: String?
	
	private var profileDisposable: Disposable?
	
	@IBOutlet private weak var messageLabel: UILabel!
	
	// MARK: Properties (Named)
	
	static let name = "ShareMessageTableViewCell"
}
