/*
See LICENSE folder for this sample’s licensing information.

Abstract:
PlaybackController creates PlayerViewControllerCoordinators and serves as the glue between the coordinators and the application's UI.
*/

import UIKit
import AVFoundation

class PlaybackController {
	
	var videos = [String: Video]()
	private var playbackItems = [Video: PlayerViewControllerCoordinator]()
	
	func prepareForPlayback() {
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback)
		} catch {
			print(error)
		}
	}
	
	private func coordinatorOrNil(for messageKey: String) -> PlayerViewControllerCoordinator? {
		guard let video = videos[messageKey] else {
			return nil
		}
		return playbackItems[video]
	}
	
	func coordinator(for messageKey: String) -> PlayerViewControllerCoordinator {
		let video = videos[messageKey]!
		if let playbackItem = playbackItems[video] {
			return playbackItem
		} else {
			let playbackItem = PlayerViewControllerCoordinator(video: video)
			playbackItems[video] = playbackItem
			return playbackItem
		}
	}
	
	func messageKey(for coordinator: PlayerViewControllerCoordinator) -> String? {
		return videos.first { (arg0) -> Bool in
			let (_, value) = arg0
			return value.hlsUrl == coordinator.video.hlsUrl
		}?.key
	}
		
	func present(contentForMessageKey messageKey: String, from presentingViewController: UIViewController) {
		coordinator(for: messageKey).presentFullScreen(from: presentingViewController)
	}
		
	func dismissActivePlayerViewController(animated: Bool, completion: @escaping () -> Void) {
		let fullScreenItems = playbackItems
			.filter { $0.value.status.contains(.fullScreenActive) }
			.map { $0.value }
		assert(fullScreenItems.count <= 1, "Never should be more than one thing full screen!")
		if let fullScreenItem = fullScreenItems.first {
			fullScreenItem.dismiss(completion: completion)
		} else {
			completion()
		}
	}
}
