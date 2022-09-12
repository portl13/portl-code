/*
See LICENSE folder for this sample’s licensing information.

Abstract:
PlayerViewControllerCoordinator wraps an AVPlayerViewController and an AVPlayer,
showing one approach to tracking and managing a playback state across multiple view hierarchies and application contexts.
*/

import AVKit

class PlayerViewControllerCoordinator: NSObject {
	
	// MARK: - Initialization
	
	init(video: Video) {
		self.video = video
		super.init()
	}
		
	// MARK: - Properties

	var video: Video
	private(set) var status: Status = [] {
		didSet {
			if oldValue.isBeingShown && !status.isBeingShown {
				playerViewControllerIfLoaded = nil
			}
		}
	}
		
	private(set) var playerViewControllerIfLoaded: AVPlayerViewController? {
		didSet {
			guard playerViewControllerIfLoaded != oldValue else { return }
			
			// 1) Invalidate KVO, delegate, player, status for old player view controller
			
			readyForDisplayObservation?.invalidate()
			readyForDisplayObservation = nil
			
			if oldValue?.delegate === self {
				oldValue?.delegate = nil
			}
			
			if oldValue?.hasContent(fromVideo: video) == true {
				oldValue?.player = nil
			}
			
			status = []
			
			// 2) Set up the new playerViewController
			
			if let playerViewController = playerViewControllerIfLoaded {
				
				// 2a) Assign self as delegate
				playerViewController.delegate = self
				
				// 2b) Create player for video
				if !playerViewController.hasContent(fromVideo: video) {
					let playerItem = CachingPlayerItem(url: video.hlsUrl)
					
					// Note that we seek to the resume time *before* giving the player view controller the player.
					// This is more efficient and provides better UI since media is only loaded at the actual start time.
					playerItem.seek(to: CMTime(seconds: video.resumeTime, preferredTimescale: 90_000), completionHandler: nil)
					let player = AVPlayer(playerItem: playerItem)
					player.automaticallyWaitsToMinimizeStalling = false
					playerViewController.player = player
					
				}
				
				// 2c) Update ready for display status and start observing the property
				if playerViewController.isReadyForDisplay {
					status.insert(.readyForDisplay)
				}
				
				readyForDisplayObservation = playerViewController.observe(\.isReadyForDisplay) { [weak self] observed, _ in
					if observed.isReadyForDisplay {
						self?.status.insert(.readyForDisplay)
					} else {
						self?.status.remove(.readyForDisplay)
					}
				}
			}
		}
	}
	
	// MARK: - Private vars
	
	private weak var fullScreenViewController: UIViewController?
	private var readyForDisplayObservation: NSKeyValueObservation?
}

// Utility functions for common UIKit tasks that the coordinator needs to help orchestrate.

extension PlayerViewControllerCoordinator {
	
	// Present full-screen, and then start playback. Notice that there's no reason to change the modal presentation style
	// or set the transitioning delegate -- AVPlayerViewController handles that automatically
	func presentFullScreen(from presentingViewController: UIViewController) {
		guard !status.contains(.fullScreenActive) else { return }
		loadPlayerViewControllerIfNeeded()
		guard let playerViewController = playerViewControllerIfLoaded else { return }
		presentingViewController.present(playerViewController, animated: true) {
			do{
				try AVAudioSession.sharedInstance().setCategory(.playback)
			} catch let e {
				print("error setting audio session category: \(e.localizedDescription)")
			}

			playerViewController.player?.play()
		}
	}
	
	// See the AVPlayerViewController delegate methods for obtaining the fullScreenViewController.
	func dismiss(completion: @escaping () -> Void) {
		fullScreenViewController?.dismiss(animated: true) {
			completion()
			self.status.remove(.fullScreenActive)
		}
	}
}

extension PlayerViewControllerCoordinator: AVPlayerViewControllerDelegate {
		
	// 2a) Track the presentation of AVPlayerViewController's content. Note that this may happen when we are still embedded inline.
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
        status.insert([.fullScreenActive, .beingPresented])
        
        coordinator.animate(alongsideTransition: nil) { context in
            self.status.remove(.beingPresented)
            // You must check context.isCancelled to determine whether or not the transition was successful.
            if context.isCancelled {
                self.status.remove(.fullScreenActive)
            } else {
                // Keep note of the view controller that was used to present full screen.
                self.fullScreenViewController = context.viewController(forKey: .to)
            }
        }
	}
	
	// 2b) Track the dismissal of AVPlayerViewControllers's content from full screen. This is
	// The mirror image of func playerViewController(_:willBeginFullScreenPresentationWithAnimationCoordinator:)
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
        status.insert([.beingDismissed])
        
        coordinator.animate(alongsideTransition: nil) { context in
            self.status.remove(.beingDismissed)
            if !context.isCancelled {
                self.status.remove(.fullScreenActive)
            }
        }
    }
}

extension PlayerViewControllerCoordinator {
	
	private func loadPlayerViewControllerIfNeeded() {
		if playerViewControllerIfLoaded == nil {
			playerViewControllerIfLoaded = AVPlayerViewController()
		}
	}
}

extension PlayerViewControllerCoordinator {
	
	// OptionSet describing the various states we are tracking in the debug hud.
	struct Status: OptionSet {
		
		let rawValue: Int
		
		static let fullScreenActive = Status(rawValue: 1 << 1)
		static let beingPresented = Status(rawValue: 1 << 2)
		static let beingDismissed = Status(rawValue: 1 << 3)
		static let readyForDisplay = Status(rawValue: 1 << 4)
		
		static let descriptions: [(Status, String)] = [
			(.fullScreenActive, "Full Screen Active"),
			(.beingPresented, "Being Presented"),
			(.beingDismissed, "Being Dismissed"),
			(.readyForDisplay, "Ready For Display")
		]
		
		var isBeingShown: Bool {
			return !intersection([.fullScreenActive]).isEmpty
		}
	}
}

private extension AVPlayerViewController {
	
	func hasContent(fromVideo video: Video) -> Bool {
		let url = (player?.currentItem?.asset as? AVURLAsset)?.url
		return url == video.hlsUrl
	}
}
