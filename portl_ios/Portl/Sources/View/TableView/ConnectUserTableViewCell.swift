//
//  ConnectUserTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 8/6/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

class ConnectUserTableViewCell: UITableViewCell, ConnectEnabledCell {
	// MARK: Configure
	
	func configureButtonsForStyle(_ style: ConnectButtonStyle) {
		guard Auth.auth().currentUser?.isAnonymous != true else {
			actionButton.isHidden = true
			declineButton.isHidden = true
			return
		}
		
		actionButton.isHidden = false
		actionButton.removeTarget(nil, action: nil, for: .allEvents)
		actionButtonTrailing.constant = ConnectUserTableViewCell.actionButtonTrailingDefault
		
		declineButton.isHidden = true
		
		switch style {
		case .connected, .sentPending:
			actionButton.backgroundColor = .black
			actionButton.setTitleColor(.white, for: .normal)
			actionButton.layer.borderColor = UIColor.white.cgColor
			actionButton.layer.borderWidth = 1.0
			actionButton.layer.cornerRadius = 5.0
		default:
			actionButton.backgroundColor = .white
			actionButton.setTitleColor(.black, for: .normal)
			actionButton.layer.borderColor = UIColor.white.cgColor
			actionButton.layer.cornerRadius = 5.0
		}
		
		switch style {
		case .connected:
			actionButton.setTitle("Connected", for: .normal)
			actionButton.addTarget(self, action: #selector(disconnect), for: .touchUpInside)
		case .notConnected:
			actionButton.setTitle("Connect", for: .normal)
			actionButton.addTarget(self, action: #selector(connect), for: .touchUpInside)
		case .receivedPending:
			actionButton.setTitle("Accept", for: .normal)
			actionButton.addTarget(self, action: #selector(approve), for: .touchUpInside)
			declineButton.isHidden = false
			actionButtonTrailing.constant = ConnectUserTableViewCell.actionButtonTrailingDefault + ConnectUserTableViewCell.widthForDeclineButton
		case .sentPending:
			actionButton.setTitle("Requested", for: .normal)
			actionButton.addTarget(self, action: #selector(cancelSent), for: .touchUpInside)
		}
		
		layoutIfNeeded()
	}
	
	// MARK: ConnectEnabledCell
	
	@IBAction func connect(_ sender: Any?) {
		spinner.startAnimating()
		actionButton.isHidden = true
		delegate?.connectEnabledCellDidSelectConnect(self)
	}
	
	@IBAction func cancelSent(_ sender: Any?) {
		spinner.startAnimating()
		actionButton.isHidden = true
		delegate?.connectEnabledCellDidSelectCancel(self)
	}
	
	@IBAction func approve(_ sender: Any?) {
		spinner.startAnimating()
		actionButton.isHidden = true
		declineButton.isHidden = true
		delegate?.connectEnabledCellDidSelectApprove(self)
	}
	
	@IBAction func disconnect(_ sender: Any?) {
		spinner.startAnimating()
		actionButton.isHidden = true
		delegate?.connectEnabledCellDidSelectDisconnect(self)
	}
	
	@IBAction func decline(_ sender: Any?) {
		spinner.startAnimating()
		actionButton.isHidden = true
		declineButton.isHidden = true
		delegate?.connectEnabledCellDidSelectDecline(self)
	}
	
	// MARK: Private
	
	private func resetCell() {
		profileImageView.sd_cancelCurrentImageLoad()
		profileImageView.image = nil
		profileImageView.sd_imageIndicator?.startAnimatingIndicator()
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		profileImageView.layer.cornerRadius = 16.0
		profileImageView.layer.borderColor = UIColor.white.cgColor
		profileImageView.layer.borderWidth = 1.0
		profileImageView.clipsToBounds = true
		profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.white
		
		actionButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
		actionButton.layer.borderColor = UIColor.white.cgColor
		actionButton.layer.borderWidth = 1.0
		actionButton.layer.cornerRadius = 5.0
		
		resetCell()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		resetCell()
	}
	
	// MARK: Properties
	
	weak var delegate: ConnectEnabledCellDelegate?
	@IBOutlet weak var profileImageView: UIImageView!
	@IBOutlet weak var actionButton: UIButton!
	@IBOutlet weak var actionButtonTrailing: NSLayoutConstraint!
	@IBOutlet weak var declineButton: UIButton!
	@IBOutlet weak var hr: UIView!
	@IBOutlet weak var spinner: UIActivityIndicatorView!

	// MARK: Properties (Const)
	
	let defaultProfileImage = UIImage(named: "img_profile_placeholder")
	
	// MARK: Properties (Static Const)
	
	static let actionButtonTrailingDefault: CGFloat = 16.0
	static let widthForDeclineButton: CGFloat = /* width */24.0 + /* leading */16.0
}
