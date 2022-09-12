//
//  VideoUtils.swift
//  Portl
//
//  Created by Jeff Creed on 2/3/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import AVKit

class VideoUtils {
	static func createThumbnailOfVideoFromUrl(url: URL) -> UIImage? {
		let asset = AVAsset(url: url)
		let assetImgGenerate = AVAssetImageGenerator(asset: asset)
		assetImgGenerate.appliesPreferredTrackTransform = true
		//Can set this to improve performance if target size is known before hand
		//assetImgGenerate.maximumSize = CGSize(width,height)
		var time = asset.duration
		time.value = 0
		
		do {
			let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
			let thumbnail = UIImage(cgImage: img)
			return thumbnail
		} catch {
		  print(error.localizedDescription)
		  return nil
		}
	}
}
