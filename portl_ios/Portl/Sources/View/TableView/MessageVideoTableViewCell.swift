//
//  MessageVideoTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 1/7/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import CSkyUtil
import AVKit

class MessageVideoTableViewCell: UITableViewCell, Named {
	// MARK: Configuration
	
	func configure(withVideoURL videoURL: URL) {
		let asset = AVAsset(url: videoURL)
		let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["playable"])
				
		player = AVPlayer(playerItem: playerItem)
		let newPlayerLayer = AVPlayerLayer(player: player)
		newPlayerLayer.frame = videoView.frame
		newPlayerLayer.videoGravity = .resizeAspectFill
		newPlayerLayer.needsDisplayOnBoundsChange = true
		if let playerLayer = playerLayer {
			videoView.layer.replaceSublayer(playerLayer, with: newPlayerLayer)
		} else {
			videoView.layer.addSublayer(newPlayerLayer)
		}
		playerLayer = newPlayerLayer
		layoutSubviews()
	}
	
	// MARK: Private
	
	@IBAction private func startPlayer(_ sender: Any) {
		if player?.timeControlStatus != .playing && player?.timeControlStatus != .waitingToPlayAtSpecifiedRate {
			playButton.isHidden = true
			player?.play()
			videoView.addGestureRecognizer(stopGestureRecognizer!)
			videoView.isUserInteractionEnabled = true
		}
	}
	
	@IBAction private func stopPlayer(_ sender: Any) {
		if player?.timeControlStatus == .playing {
			player?.pause()
			videoView.isUserInteractionEnabled = false
			videoView.removeGestureRecognizer(stopGestureRecognizer!)
			playButton.isHidden = false
		}
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		stopGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(stopPlayer))
	}
	
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.playerLayer?.frame = videoView.bounds
	}
	
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var videoView: UIView!
	@IBOutlet private weak var playButton: UIButton!
	
	private var player: AVPlayer?
	private var playerLayer: CALayer?
	private var stopGestureRecognizer: UITapGestureRecognizer?

	// MARK: Properties (Named)
	
	static let name = "MessageVideoTableViewCell"
}
