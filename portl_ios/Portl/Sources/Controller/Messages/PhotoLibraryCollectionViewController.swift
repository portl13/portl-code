//
//  PhotoLibraryCollectionViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Photos

protocol PhotoLibraryCollectionViewControllerDelegate: class {
	func photoLibraryCollectionViewController(_ photoLibraryCollectionViewController: PhotoLibraryCollectionViewController, choseImage image: UIImage?)
	func photoLibraryCollectionViewController(_ photoLibraryCollectionViewController: PhotoLibraryCollectionViewController, choseVideo videoURL: URL)
}

class PhotoLibraryCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
	
	// MARK: UICollectionViewDataSource
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return assets?.count ?? 0
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return collectionView.dequeue(ImageCollectionViewCell.self, for: indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		let requestOptions = PHImageRequestOptions()
		requestOptions.deliveryMode = .highQualityFormat
		
		let asset = assets![indexPath.row]
		
		PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: cellSize, height: cellSize), contentMode: .aspectFill, options: requestOptions) { (image, info) in
			(cell as! ImageCollectionViewCell).image = image
		}
		
		if (asset.mediaType == .video) {
			(cell as! ImageCollectionViewCell).videoLengthSeconds = asset.duration
		}
	}
	
	// MARK: UICollectionViewDelegate
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let asset = assets![indexPath.row]
		
		if asset.mediaType == .video {
			PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { (asset, _, _) in
				guard let assetURL = asset as? AVURLAsset else {
					return
				}
				self.delegate?.photoLibraryCollectionViewController(self, choseVideo: assetURL.url)
			}
		} else {
			let requestImageOption = PHImageRequestOptions()
			requestImageOption.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
			PHImageManager.default().requestImage(for: assets![indexPath.row], targetSize: PHImageManagerMaximumSize, contentMode: .default, options: requestImageOption) { (image, info) in
				self.delegate?.photoLibraryCollectionViewController(self, choseImage: image)
			}
		}
	}
	
	// MARK: Private
	
	private func reloadAssets() {
		spinner.startAnimating()
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
		assets = PHAsset.fetchAssets(with: fetchOptions)
		collectionView.reloadData()
		spinner.stopAnimating()
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		collectionView.registerNib(ImageCollectionViewCell.self)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		cellSize = (collectionView.bounds.width - 4) / 3
		collectionViewLayout.itemSize = CGSize(width: cellSize, height: cellSize)
		collectionViewLayout.minimumLineSpacing = 2
		collectionViewLayout.minimumInteritemSpacing = 2
		
		if PHPhotoLibrary.authorizationStatus() == .authorized {
			reloadAssets()
		} else {
			PHPhotoLibrary.requestAuthorization({ (status) -> Void in
				if status == .authorized {
					self.reloadAssets()
				} else {
					self.presentErrorAlert(withMessage: "Access to photos is required.", completion: nil)
				}
			})
		}
	}
	
	// MARK: Properties
	
	var delegate: PhotoLibraryCollectionViewControllerDelegate?
	
	// MARK: Properties (Private)
	
	private var assets: PHFetchResult<PHAsset>?
	private var cellSize: CGFloat!
	
	@IBOutlet private weak var collectionView: UICollectionView!
	@IBOutlet private weak var spinner: UIActivityIndicatorView!
	@IBOutlet private weak var collectionViewLayout: UICollectionViewFlowLayout!
}
