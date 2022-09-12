//
//  PhotoPickerViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil
import Photos
import CropViewController
import AVKit

class PhotoPickerViewController: UIViewController, PhotoLibraryCollectionViewControllerDelegate, CameraViewControllerDelegate, CropViewControllerDelegate, UINavigationControllerDelegate & UIVideoEditorControllerDelegate {

	func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		let viewControllerType = type(of: viewController)
		if viewControllerType == CreateMessageViewController.self {
			videoURLForSegue = nil
			spinnerView.isHidden = true
			cameraPicker.resetUI()
		}
	}
	
	// MARK: UIVideoEditorControllerDelegate
	
	func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
		cameraPicker.resetUI()
		editor.dismiss(animated: true, completion: nil)
	}
	
	func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
		spinnerView.isHidden = false
		editor.delegate = nil

		AVURLAsset(url: URL(fileURLWithPath: editedVideoPath)).exportVideo {[weak self] (url) in
			guard let url = url else { return }
			self?.videoURLForSegue = url
			self?.imageForSegue = nil
			DispatchQueue.main.async {
				self?.performSegue(withIdentifier: PhotoPickerViewController.textSegueIdentifier, sender: self)
			}
		}
	}
	
	func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
		// TODO: Present error ?
	}
	
	func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
		imageForSegue = image
		videoURLForSegue = nil
		performSegue(withIdentifier: PhotoPickerViewController.textSegueIdentifier, sender: self)
	}
	
	// MARK: CameraViewControllerDelegate
	
	func cameraViewController(_ cameraViewController: CameraViewController, tookImage image: UIImage?) {
		cameraViewController.delegate = nil
		showCropViewController(withSourceImage: image)
	}
	
	func cameraViewController(_ cameraViewController: CameraViewController, tookVideo videoURL: URL) {
		cameraViewController.delegate = nil
		let trimController = UIVideoEditorController()
		trimController.videoMaximumDuration = 30
		trimController.videoPath = videoURL.path
		trimController.delegate = self
		navigationController?.show(trimController, sender: self)
	}
	
	// MARK: PhotoLibraryCollectionViewControllerDelegate
	
	func photoLibraryCollectionViewController(_ photoLibraryCollectionViewController: PhotoLibraryCollectionViewController, choseImage image: UIImage?) {
		photoLibraryCollectionViewController.delegate = nil
		showCropViewController(withSourceImage: image)
	}
	
	func photoLibraryCollectionViewController(_ photoLibraryCollectionViewController: PhotoLibraryCollectionViewController, choseVideo videoURL: URL) {
		DispatchQueue.main.async {
			let trimController = UIVideoEditorController()
			trimController.videoMaximumDuration = 20
			trimController.videoPath = videoURL.path
			trimController.delegate = self
			self.navigationController?.show(trimController, sender: self)
		}
	}

	// MARK: Private
	
	private func showCropViewController(withSourceImage sourceImage: UIImage?) {
		if let image = sourceImage {
			let cropViewController = CropViewController(image: image)
			cropViewController.aspectRatioPreset = .preset4x3
			cropViewController.aspectRatioLockEnabled = true
			cropViewController.resetAspectRatioEnabled = false
			cropViewController.delegate = self
			self.navigationController?.show(cropViewController, sender: self)
		}
	}
	
	@IBAction private func setCamera(_ sender: Any) {
		if let camera = cameraPicker {
			camera.isVideoMode = false
			camera.delegate = self
			setCurrentImagePicker(camera)
			cameraButton.setImage(PhotoPickerViewController.cameraActiveIcon, for: .normal)
			libraryButton.setImage(PhotoPickerViewController.libraryIcon, for: .normal)
			videoButton.setImage(PhotoPickerViewController.videoIcon, for: .normal)
			cameraSelectedView.isHidden = false
			librarySelectedView.isHidden = true
			videoSelectedView.isHidden = true
		}
	}
	
	@IBAction private func setVideo(_ sender: Any) {
		if let camera = cameraPicker {
			camera.isVideoMode = true
			camera.delegate = self
			setCurrentImagePicker(camera)
			cameraButton.setImage(PhotoPickerViewController.cameraIcon, for: .normal)
			libraryButton.setImage(PhotoPickerViewController.libraryIcon, for: .normal)
			videoButton.setImage(PhotoPickerViewController.videoActiveIcon, for: .normal)
			cameraSelectedView.isHidden = true
			librarySelectedView.isHidden = true
			videoSelectedView.isHidden = false
		}
	}
	
	@IBAction private func setLibrary(_ sender: Any) {
		if let library = libraryPicker {
			library.delegate = self
			setCurrentImagePicker(library)
			cameraButton.setImage(PhotoPickerViewController.cameraIcon, for: .normal)
			libraryButton.setImage(PhotoPickerViewController.libraryActiveIcon, for: .normal)
			videoButton.setImage(PhotoPickerViewController.videoIcon, for: .normal)
			librarySelectedView.isHidden = false
			cameraSelectedView.isHidden = true
			videoSelectedView.isHidden = true
		}
	}
		
	private func setCurrentImagePicker(_ picker: UIViewController) {
		guard picker != currentImagePickerController else {
			return
		}
		
		currentImagePickerController?.willMove(toParent: nil)
		addChild(picker)
		
		picker.view.frame = containerView.frame
		picker.view.translatesAutoresizingMaskIntoConstraints = false
		currentImagePickerController?.view.removeFromSuperview()
		
		containerView.addSubview(picker.view)
		containerView.addConstraint(picker.view.topAnchor.constraint(equalTo: containerView.topAnchor))
		containerView.addConstraint(picker.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor))
		containerView.addConstraint(picker.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor))
		containerView.addConstraint(picker.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor))
		
		currentImagePickerController?.removeFromParent()
		picker.didMove(toParent: self)
		
		currentImagePickerController = picker
	}
	
	@IBAction private func onClose(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "cropSegue" {
		} else {
			let controller = segue.destination as! CreateMessageViewController
			controller.image = imageForSegue
			controller.videoURL = videoURLForSegue
			controller.isExperience = isExperience
		}
	}
	
	// MARK: Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.title = "Share an Experience"
		
		let closeItem = UIBarButtonItem(image: UIImage(named: "icon_close"), style: .plain, target: self, action: #selector(onClose))
		closeItem.tintColor = PaletteColor.light1.uiColor
		self.navigationItem.leftBarButtonItem = closeItem

		libraryPicker = (UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "PhotoLibraryCollectionViewController") as! PhotoLibraryCollectionViewController)
		cameraPicker = (UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController)
		cameraLabel.attributedText = NSAttributedString(string: PhotoPickerViewController.cameraLabelText, textStyle: .small)
		libraryLabel.attributedText = NSAttributedString(string: PhotoPickerViewController.libraryLabelText, textStyle: .small)
		videoLabel.attributedText = NSAttributedString(string: PhotoPickerViewController.videoLabelText, textStyle: .small)
		
		setCamera(self)
		
		navigationController?.delegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		libraryPicker.delegate = self
		cameraPicker.delegate = self
	}
		
	// MARK: Properties
	
	var isExperience = false
	
	// MARK: Properties (Private)
	
	private var imageForSegue: UIImage?
	private var videoURLForSegue: URL?
	
	@IBOutlet private weak var cameraSelectedView: UIView!
	@IBOutlet private weak var cameraButton: UIButton!
	@IBOutlet private weak var cameraLabel: UILabel!
	@IBOutlet private weak var librarySelectedView: UIView!
	@IBOutlet private weak var libraryButton: UIButton!
	@IBOutlet private weak var libraryLabel: UILabel!
	@IBOutlet private weak var videoSelectedView: UIView!
	@IBOutlet private weak var videoButton: UIButton!
	@IBOutlet private weak var videoLabel: UILabel!
	@IBOutlet private weak var spinnerView: UIView!
	
	@IBOutlet private weak var containerView: UIView!
	private weak var currentImagePickerController: UIViewController?
	
	private var cameraPicker: CameraViewController!
	private var libraryPicker: PhotoLibraryCollectionViewController!
	
	// MARK: Properties (Private Static)
	
	private static let videoLabelText = "Video"
	private static let cameraLabelText = "Camera"
	private static let libraryLabelText = "Photos"
	private static let cameraIcon = UIImage(named: "icon_camera")
	private static let cameraActiveIcon = UIImage(named: "icon_camera_active")
	private static let libraryIcon = UIImage(named: "icon_library")
	private static let libraryActiveIcon = UIImage(named: "icon_library_active")
	private static let videoIcon = UIImage(named: "icon_video")
	private static let videoActiveIcon = UIImage(named: "icon_video_active")
	private static let textSegueIdentifier = "messageTextSegue"
}
