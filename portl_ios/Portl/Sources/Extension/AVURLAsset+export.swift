//
//  AVURLAsset+export.swift
//  Portl
//
//  Created by Jeff Creed on 2/11/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import AVFoundation

extension AVURLAsset {
	func exportVideo(presetName: String = AVAssetExportPresetHighestQuality, outputFileType: AVFileType = .mp4, fileExtension: String = "mp4", completion: @escaping (URL?) -> Void) {
        let filename = url.deletingPathExtension().appendingPathExtension(fileExtension).lastPathComponent
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        if let session = AVAssetExportSession(asset: self, presetName: presetName) {
            session.outputURL = outputURL
            session.outputFileType = outputFileType
			let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
			let range = CMTimeRangeMake(start: start, duration: duration)
            session.timeRange = range
            session.shouldOptimizeForNetworkUse = true
            session.exportAsynchronously {
                switch session.status {
                case .completed:
                    completion(outputURL)
                case .cancelled:
                    debugPrint("Video export cancelled.")
                    completion(nil)
                case .failed:
                    let errorMessage = session.error?.localizedDescription ?? "n/a"
                    debugPrint("Video export failed with error: \(errorMessage)")
                    completion(nil)
                default:
                    break
                }
            }
        } else {
            completion(nil)
        }
    }
}
