//
//  CameraViewController.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import AVFoundation
import Photos

protocol CameraViewControllerDelegate: class {
	func cameraViewController(_ cameraViewController: CameraViewController, tookImage image: UIImage?)
	func cameraViewController(_ cameraViewController: CameraViewController, tookVideo videoURL: URL)
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
	
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		guard error == nil else {
			print("Error recording video: \(error!.localizedDescription)")
			return
		}
		delegate?.cameraViewController(self, tookVideo: outputFileURL)
	}
	
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		guard let imageData = photo.fileDataRepresentation() else {
			return
		}
		
		guard let image = UIImage(data: imageData) else {
			return
		}
		
		delegate?.cameraViewController(self, tookImage: image)
	}
	
	func resetUI() {
		recordSeconds = 0
		videoTimeLabel.text = "00:00"
	}
	
	// MARK: Private
	
	@IBAction private func captureButtonPressed(_ sender: Any) {
		if !isVideoMode {
			let settings = AVCapturePhotoSettings()
			let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
			let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
							 kCVPixelBufferWidthKey as String: 160,
							 kCVPixelBufferHeightKey as String: 160]
			settings.previewPhotoFormat = previewFormat

			stillImageOutput?.capturePhoto(with: settings, delegate: self)
		} else {
			if videoOutput?.isRecording == false {
				startRecording()
			} else if videoOutput?.isRecording == true {
				stopRecording()
			}
		}
	}
	
	private func startRecording() {
		let connection = videoOutput?.connection(with: .video)
		
		if connection?.isVideoOrientationSupported == true {
			connection?.videoOrientation = currentVideoOrientation()
		}
		
		if connection?.isVideoStabilizationSupported  == true {
			connection?.preferredVideoStabilizationMode = .auto
		}
		
		let device = captureInput.device
		if device.isSmoothAutoFocusSupported {
			do {
				try device.lockForConfiguration()
				device.isSmoothAutoFocusEnabled = false
				device.unlockForConfiguration()
			} catch let e {
				print("Error configuring device: \(e.localizedDescription)")
			}
		}
		
		outputURL = tempURL()
		if let url = outputURL {
			DispatchQueue.main.async {
				self.videoOutput?.startRecording(to: url, recordingDelegate: self)
				self.captureButton.setImage(CameraViewController.videoButtonActiveIcon, for: .normal)
				self.videoRecordIcon.isHidden = false
				self.recordTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimerLabel), userInfo: nil, repeats: true)
			}
		}
	}
	
	@IBAction private func updateTimerLabel(_ sender: Any) {
		recordSeconds += 1
		let minutes = recordSeconds / 60
		let seconds = recordSeconds % 60
		
		videoTimeLabel.text = "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
	}
	
	private func stopRecording() {
		if videoOutput?.isRecording == true {
			captureButton.setImage(CameraViewController.videoButtonIcon, for: .normal)
			videoOutput?.stopRecording()
			videoRecordIcon.isHidden = true
			
			recordTimer?.invalidate()
			recordTimer = nil
		}
	}
	
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
		let orientation: AVCaptureVideoOrientation

        switch UIDevice.current.orientation {
            case .portrait:
                orientation = .portrait
            case .landscapeRight:
                orientation = .landscapeLeft
            case .portraitUpsideDown:
                orientation = .portraitUpsideDown
            default:
                 orientation = .landscapeRight
         }

         return orientation
     }

    private func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString

        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".MOV")
            return URL(fileURLWithPath: path)
        }

        return nil
    }

	private func initializeSession() {
		if session?.isRunning == true {
			session?.stopRunning()
		}
		
		session = AVCaptureSession()

		session!.sessionPreset = isVideoMode ? .high : .photo
		
		if let backCamera = AVCaptureDevice.default(for: .video), let microphone = AVCaptureDevice.default(for: .audio) {
			var error: NSError?
			var micInput: AVCaptureDeviceInput!
			
			do {
				captureInput = try AVCaptureDeviceInput(device: backCamera)
				micInput = try AVCaptureDeviceInput(device: microphone)
			} catch let e as NSError {
				error = e
				captureInput = nil
				micInput = nil
				print(e.localizedDescription)
			}
			
			if error == nil && session!.canAddInput(captureInput) && session!.canAddInput(micInput) {
				session!.beginConfiguration()
				
				session!.addInput(captureInput)
				session!.addInput(micInput)
				stillImageOutput = AVCapturePhotoOutput()
				videoOutput = AVCaptureMovieFileOutput()
				
				if (!isVideoMode && session!.canAddOutput(stillImageOutput!)) || (isVideoMode && session!.canAddOutput(videoOutput!)) {
					if !isVideoMode {
						session!.addOutput(stillImageOutput!)
					} else {
						session!.addOutput(videoOutput!)
					}
					
					session!.commitConfiguration()
					videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
					videoPreviewLayer!.videoGravity = .resizeAspectFill
					videoPreviewLayer!.connection?.videoOrientation = .portrait
					previewImageView.layer.addSublayer(videoPreviewLayer!)
					session!.startRunning()
					isSessionRunning = session!.isRunning
				}
				
				videoPreviewLayer!.frame = previewImageView.bounds
			}
		}
	}
	
	@IBAction private func zoom(_ gestureRecognizer: UIGestureRecognizer) {
		guard gestureRecognizer.view != nil else { return }
		let device = captureInput.device
		
		var zoomFactor = ((gestureRecognizer as! UIPinchGestureRecognizer).scale)
		do {
			try device.lockForConfiguration()
			defer {device.unlockForConfiguration()}
			if (zoomFactor <= device.activeFormat.videoMaxZoomFactor && zoomFactor >= 1.0) {
				device.videoZoomFactor = zoomFactor
			}
		} catch let error {
			NSLog("Unable to set videoZoom: %@", error.localizedDescription);
		}
	}
	
	@IBAction private func sessionWasInterrupted(notification: NSNotification) {
		
	}
	
	@IBAction private func sessionInterruptionEnded(notification: NSNotification) {
		
	}
	
	@IBAction private func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session?.startRunning()
                    self.isSessionRunning = self.session?.isRunning == true
                }
            }
        }
	}
	
	
	private func registerForNotifications() {
		unregisterObservers()
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(sessionWasInterrupted),
											   name: .AVCaptureSessionWasInterrupted,
											   object: session)
		NotificationCenter.default.addObserver(self,
											   selector: #selector(sessionInterruptionEnded),
											   name: .AVCaptureSessionInterruptionEnded,
											   object: session)

		
		observerTokens.append(NotificationCenter.default.addObserver(self,
											   selector: #selector(sessionRuntimeError),
											   name: .AVCaptureSessionRuntimeError,
											   object: session))
	}
	
	private func unregisterObservers() {
		for token in observerTokens {
			NotificationCenter.default.removeObserver(token)
		}
	}
	
	// MARK: Life Cycle
		
	override func viewDidLoad() {
		super.viewDidLoad()
		view.isUserInteractionEnabled = true
		view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(zoom)))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		registerForNotifications()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		sessionQueue.async {
			self.unregisterObservers()
			if self.isSessionRunning {
				self.session?.stopRunning()
				self.isSessionRunning = self.session?.isRunning == true
			}
		}
		
		super.viewWillDisappear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		let buttonImage = isVideoMode ? CameraViewController.videoButtonIcon : CameraViewController.cameraButtonIcon
		captureButton.setImage(buttonImage, for: .normal)
		videoInfoView.isHidden = !isVideoMode
		
		if PHPhotoLibrary.authorizationStatus() == .authorized {
			initializeSession()
		} else {
			PHPhotoLibrary.requestAuthorization({ (status) -> Void in
				if status == .authorized {
					DispatchQueue.main.async {
						self.initializeSession()
					}
				} else {
					self.presentErrorAlert(withMessage: "Access to photos is required.", completion: nil)
				}
			})
		}
	}
	
	// MARK: Properties
	
	var delegate: CameraViewControllerDelegate?
	var isVideoMode = false {
		didSet {
			if isViewLoaded {
				let buttonImage = isVideoMode ? CameraViewController.videoButtonIcon : CameraViewController.cameraButtonIcon
				captureButton.setImage(buttonImage, for: .normal)
				videoInfoView.isHidden = !isVideoMode
			}
			
			if viewIfLoaded?.window != nil {
				initializeSession()
			}
		}
	}
	
	// MARK: Properties (Private)
		
	@IBOutlet private weak var previewImageView: UIImageView!
	@IBOutlet private weak var captureButton: UIButton!
	@IBOutlet private weak var videoInfoView: UIView!
	@IBOutlet private weak var videoTimeLabel: UILabel!
	@IBOutlet private weak var videoRecordIcon: UIImageView!
	
	private var session: AVCaptureSession?
	private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue")
	
	private var captureInput: AVCaptureDeviceInput!
	private var stillImageOutput: AVCapturePhotoOutput?
	private var videoOutput: AVCaptureMovieFileOutput?
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	private var outputURL: URL?
	
	private var recordTimer: Timer?
	private var recordSeconds = 0
	
	private var observerTokens = [Any]()
	
	// MARK: Properties (Private Static)
	
	private static let cameraButtonIcon = UIImage(named: "icon_camera_button")
	private static let videoButtonIcon = UIImage(named: "icon_video_button")
	private static let videoButtonActiveIcon = UIImage(named: "icon_video_button_active")
}
