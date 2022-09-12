//
//  ProfileEditViewController.swift
//  Portl
//
//  Created by Jeff Creed on 6/2/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import FirebaseStorage
import Photos
import CSkyUtil
import RxSwift

class ProfileEditViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate, GenderPickerViewControllerDelegate, DatePickerViewControllerDelegate, UITextFieldDelegate {
	// MARK: UITextFieldDelegate
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).count + string.trimmingCharacters(in: .whitespacesAndNewlines).count - range.length <= 32
	}
	
	// MARK: DatePickerViewControllerDelegate
	
	func datePickerViewController(_ datePickerViewController: DatePickerViewController, didSelectDate date: Date) {
		profileService.updateBirthday(birthday: birthdayDateFormatter.string(from: date)) {[unowned self] (error) in
			if error != nil {
				self.presentErrorAlert(withMessage: nil, completion: nil)
			}
		}
		datePickerViewController.dismiss(animated: true, completion: nil)
	}
	
	func datePickerViewControllerDidCancel(_ datePickerViewController: DatePickerViewController) {
		datePickerViewController.dismiss(animated: true, completion: nil)
	}
	
	
	// MARK: GenderPickerViewControllerDelegate
	
	func genderPickerViewControllerDidCancel(_ genderPickerViewController: GenderPickerViewController) {
		genderPickerViewController.dismiss(animated: true, completion: nil)
	}
	
	func genderPickerViewController(_ genderPickerViewController: GenderPickerViewController, didSelectGender gender: String) {
		FIRPortlAuthenticator.shared().updateProfileGender(gender)
		genderPickerViewController.dismiss(animated: true, completion: nil)
	}
	
	// MARK: UICollectionViewDataSource
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard profile != nil else {
			return 0
		}
		return ProfileEditRow.count.rawValue
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let row = ProfileEditRow(rawValue: indexPath.row)!
		switch row {
		case .image:
			let cell = collectionView.dequeue(ProfileEditPictureCollectionViewCell.self, for: indexPath)
			cell.configure(withImageURL: profile?.avatar)
			return cell
		case .privateHeader:
			let cell = collectionView.dequeue(ProfileEditPrivateSectionCollectionViewCell.self, for: indexPath)
			return cell
		case .dob:
			let cell = collectionView.dequeue(ProfileEditTextPropertyCollectionViewCell.self, for: indexPath)
			if let bdayString = profile?.birthDate, let date = birthdayDateFormatter.date(from: bdayString) {
				cell.configureCell(withName: "Date of Birth", andValue: displayDateFormatter.string(from: date) , showHorizontalRule: true)
			} else {
				cell.configureCell(withName: "Date of Birth", andValue: nil , showHorizontalRule: true)
			}
			return cell
		case .username:
			let cell = collectionView.dequeue(ProfileEditTextPropertyCollectionViewCell.self, for: indexPath)
			cell.configureCell(withName: "Username", andValue: profile?.username, showHorizontalRule: true)
			return cell
		default:
			let nameValue = getProfileNameAndValue(forProfileEditRow: row)
			let cell = collectionView.dequeue(ProfileEditTextPropertyCollectionViewCell.self, for: indexPath)
			cell.configureCell(withName: nameValue.first!.key, andValue: nameValue.first!.value, showHorizontalRule: row != .gender)
			return cell
		}
	}
	
	// MARK: UICollectionViewDelegate
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: false)
		
		let row = ProfileEditRow(rawValue: indexPath.row)!
		
		switch row {
		case .image:
			changePhoto()
		case .bio:
			performSegue(withIdentifier: bioEditSegueIdentifier, sender: self)
		case .gender:
			editGender()
		case .name:
			editFirstAndLastName()
		case .zipcode:
			editZipcode()
		case .dob:
			editBirthDay()
		case .username:
			editUsername()
		case .website:
			editWebsite()
		default:
			return
		}
	}
	
	// MARK: UICollectionViewDelegateFlowLayout
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let row = ProfileEditRow(rawValue: indexPath.row)!
		switch row {
		case .image:
			return CGSize(width: self.view.frame.size.width, height: ProfileEditPictureCollectionViewCell.heightForCell())
		case .privateHeader:
			return CGSize(width: self.view.frame.size.width, height: ProfileEditPrivateSectionCollectionViewCell.heightForCell())
		default:
			let nameValue = getProfileNameAndValue(forProfileEditRow: row)
			return CGSize(width: self.view.frame.size.width, height: ProfileEditTextPropertyCollectionViewCell.heightForCell(withWidth: self.view.frame.size.width, andValueString: nameValue.first!.value))
		}
	}
	
	// MARK: UIImagePickerControllerDelegate
	
	@objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		var chosenImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
		if chosenImage.size.width > 500 {
			chosenImage = self.getScaledImage(withImage: chosenImage, toSize: CGSize(width: 500.0, height: chosenImage.size.height * 500 / chosenImage.size.width))
		}
		if chosenImage.size.height > 500 {
			chosenImage = self.getScaledImage(withImage: chosenImage, toSize: CGSize(width: chosenImage.size.width * 500 / chosenImage.size.height, height: 500.0))
		}
		uploadingImage = chosenImage
		profileEditCollectionView.reloadItems(at: [IndexPath(item: ProfileEditRow.image.rawValue, section: 0)])
		uploadProfileImageToFirebase()
		picker.dismiss(animated: true)
	}
	
	// MARK: Firebase Storage
	
	private func uploadProfileImageToFirebase() {
		let filePath = "profile/\(profile!.uid)/\(UUID().uuidString.lowercased()).jpg"
		
		let imageData = uploadingImage!.jpegData(compressionQuality: 0.8)!
		
		let metaData = StorageMetadata()
		metaData.contentType = "image/jpg"
		
		setActivityIndicator(on: true)
		
		Storage.storage().reference().child(filePath).putData(imageData, metadata: metaData) {[unowned self] (metadata, error) in
			guard error == nil else {
				self.presentErrorAlert(withMessage: nil, completion: nil)
				print("Error uploading new profile image: \(error!)")
				return
			}
			
			Storage.storage().reference().child(filePath).downloadURL(completion: {[unowned self] (url, error) in
				self.uploadingImage = nil
				guard error == nil, let URL = url else {
					self.presentErrorAlert(withMessage: nil, completion: nil)
					print("Unable to load new profile image from url: \(error!)")
					self.profileEditCollectionView.reloadItems(at: [IndexPath(item: ProfileEditRow.image.rawValue, section: 0)])
					return
				}
				
				self.profileService.updateAvatar(urlString: URL.absoluteString, completion: { (error) in
					self.setActivityIndicator(on: false)
					if error != nil {
						self.presentErrorAlert(withMessage: nil, completion: nil)
					}
				})
			})
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.title = "Edit"
		
		let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
		backItem.tintColor = .white
		navigationItem.leftBarButtonItem = backItem
		
		profileEditCollectionView.registerNib(ProfileEditPictureCollectionViewCell.self)
		profileEditCollectionView.registerNib(ProfileEditTextPropertyCollectionViewCell.self)
		profileEditCollectionView.registerNib(ProfileEditPrivateSectionCollectionViewCell.self)
		
		profileDisposable = profileService.authenticatedProfile.subscribe(onNext: {[weak self] firebaseProfile in
			self?.profile = firebaseProfile
			self?.profileEditCollectionView.reloadData()
		})

	}
	
	// MARK: Navigation
	
	@objc private func onBack() {
		self.navigationController?.popViewController(animated: true)
	}
	
	// MARK: Private
	
	private func getProfileNameAndValue(forProfileEditRow row: ProfileEditRow) -> Dictionary<String, String?> {
		switch row {
		case .name:
			return ["Name": (profile?.firstName ?? "") + " " + (profile?.lastName ?? "")]
		case .website:
			return ["Website": profile?.website]
		case .bio:
			return ["Bio": profile?.bio]
		case .email:
			return ["Email": profile?.email]
		case .zipcode:
			return ["Zipcode": profile?.zipcode]
		case .dob:
			return ["Date of Birth": profile?.birthDate]
		default:
			guard let selectedGender = profile?.gender, selectedGender.count > 0 else {
				return ["Gender": ""]
			}
			let titleIndex = GenderPickerViewController.genderStrings.firstIndex(of: selectedGender)!
			return ["Gender": GenderPickerViewController.genderTitles[titleIndex]]
		}
	}
	
	private func changePhoto() {
		let alert = UIAlertController(title: nil, message: "Change Profile Picture", preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [unowned self] action in
			let presenter =  (self.tabBarController ?? self.navigationController ?? self)
			if UIImagePickerController.isSourceTypeAvailable(.camera) {
				let picker = UIImagePickerController()
				picker.delegate = self
				picker.sourceType = .camera
				picker.modalPresentationStyle = .overFullScreen
				presenter.present(picker, animated: true, completion: nil)
			} else {
				let noCameraAlert = UIAlertController(title: nil, message: "Camera is not available on your device.", preferredStyle: .alert)
				noCameraAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
				presenter.present(noCameraAlert, animated: true, completion: nil)
			}
		}))
		
		alert.addAction(UIAlertAction(title: "Photo Album", style: .default, handler: { [unowned self] action in
			let presenter =  (self.tabBarController ?? self.navigationController ?? self)
			let picker = UIImagePickerController()
			picker.delegate = self
			picker.sourceType = .photoLibrary
			picker.modalPresentationStyle = .currentContext
			presenter.present(picker, animated: true, completion: nil)
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
	}
	
	private func getScaledImage(withImage image: UIImage, toSize size: CGSize) -> UIImage {
		UIGraphicsBeginImageContext(size)
		image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		let newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		return newImage!
	}
	
	private func editGender() {
		let genderPickerViewController = UIStoryboard(name: "pickers", bundle: nil).instantiate(GenderPickerViewController.self)
		genderPickerViewController.delegate = self
		genderPickerViewController.currentGender = profile?.gender
		(tabBarController ?? navigationController ?? self).present(genderPickerViewController, animated: true)
	}
	
	private func editBirthDay() {
		let datePickerViewController = UIStoryboard(name: "pickers", bundle: nil).instantiate(DatePickerViewController.self)
		datePickerViewController.delegate = self
		datePickerViewController.maxDate = Calendar.current.date(byAdding: .year, value: -13, to: Date())
		
		if let bdayString = profile?.birthDate {
			datePickerViewController.initialDate = birthdayDateFormatter.date(from: bdayString)
		}
		(tabBarController ?? navigationController ?? self).present(datePickerViewController, animated: true)
	}
	
	private func editFirstAndLastName() {
		let controller = UIAlertController(title: "Edit Name", message: nil, preferredStyle: .alert)
		let first = profile?.firstName
		let last = profile?.lastName
		
		controller.addTextField { field in
			field.text = first
		}
		controller.addTextField { field in
			field.text = last
		}
		
		controller.addAction(UIAlertAction(title: "Update", style: .default, handler: {[unowned self] action in
			self.profileService.updateName(firstName: controller.textFields![0].text, lastName: controller.textFields![1].text, completion: { (error) in
				if error != nil {
					self.presentErrorAlert(withMessage: nil, completion: nil)
				}
			})
		}))
		
		controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(controller, animated: true, completion: nil)
	}
	
	private func editUsername() {
		let controller = UIAlertController(title: "Edit Username", message: nil, preferredStyle: .alert)
		let username = profile?.username
		
		controller.addTextField { field in
			field.text = username
			field.delegate = self
		}
		
		controller.addAction(UIAlertAction(title: "Update", style: .default, handler: {[unowned self] action in
			guard let newUsername = controller.textFields![0].text?.trimmingCharacters(in: .whitespacesAndNewlines), newUsername.count > 0 else {
				return
			}
			
			if newUsername.count < 6 {
				let alert = UIAlertController(title: nil, message: "Username should be at least 6 characters", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
				self.present(alert, animated: true, completion: nil)
			} else {
				self.profileService.updateUsername(username: newUsername, completion: { (error) in
					guard error == nil else {
						let alert = UIAlertController(title: nil, message: "Username already taken", preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
						self.present(alert, animated: true, completion: nil)
						return
					}
				})
			}
		}))
		
		controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(controller, animated: true, completion: nil)
	}
	
	private func editZipcode() {
		let controller = UIAlertController(title: "Edit Zipcode", message: nil, preferredStyle: .alert)
		let zipcode = profile?.zipcode
		
		controller.addTextField { field in
			field.text = zipcode
			field.delegate = self
		}
		
		controller.addAction(UIAlertAction(title: "Update", style: .default, handler: {[unowned self] action in
			guard let newZipcode = controller.textFields![0].text?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .letters).trimmingCharacters(in: .symbols), newZipcode.count > 0 else {
				return
			}
			
			self.profileService.updateZipcode(zipcode: newZipcode, completion: { (error) in
				guard error == nil else {
					let alert = UIAlertController(title: nil, message: "Invalid Zipcode", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					self.present(alert, animated: true, completion: nil)
					return
				}
			})
		}))
		
		controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(controller, animated: true, completion: nil)

	}
	
	private func editWebsite() {
		let controller = UIAlertController(title: "Edit Website", message: nil, preferredStyle: .alert)
		let website = profile?.website
		
		controller.addTextField { field in
			field.text = website
			field.delegate = self
		}
		
		controller.addAction(UIAlertAction(title: "Update", style: .default, handler: {[unowned self] (action) in
			guard let updated = controller.textFields![0].text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
				return
			}
			
			if !updated.isEmpty && !updated.lowercased().starts(with: "http") {
				self.presentErrorAlert(withMessage: "A valid website must start with 'http' or 'https'", completion: nil)
				return
			}
			
			self.profileService.updateWebsite(website: updated, completion: { (error) in
				guard error == nil else {
					let alert = UIAlertController(title: nil, message: "Error updating", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					self.present(alert, animated: true, completion: nil)
					return
				}
			})
		}))
		
		controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(controller, animated: true, completion: nil)
	}
	
	private func setActivityIndicator(on: Bool) {
		loadingView.isHidden = !on
		if on { activityIndicator.startAnimating() } else { activityIndicator.stopAnimating() }
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		Injector.root?.inject(into: inject)
	}
	
	private func inject(profileService: UserProfileService, displayDateFormatter: NoTimeDateFormatterQualifier, birthdayDateFormatter: BirthdayDateFormatterQualifier) {
		self.profileService = profileService
		self.displayDateFormatter = displayDateFormatter.value
		self.birthdayDateFormatter = birthdayDateFormatter.value
	}
	
	deinit {
		profileDisposable?.dispose()
	}
	
	// MARK: Properties
	
	var profile: FirebaseProfile?
	
	// MARK: Properties (Private)
	
	private var profileDisposable: Disposable?
	
	private var uploadingImage: UIImage?
	private var profileService: UserProfileService!
	private var displayDateFormatter: DateFormatter!
	private var birthdayDateFormatter: DateFormatter!
	
	@IBOutlet private var loadingView: UIView!
	@IBOutlet private var activityIndicator: UIActivityIndicatorView!
	
	// MARK: Properties (Private Constant)
	
	private let bioEditSegueIdentifier = "bioEditSegue"
	private let uidKey = "uid"
	private let avatarKey = "avatar"
	private let firstNameKey = "first_name"
	private let lastNameKey = "last_name"
	private let bioKey = "bio"
	private let websiteKey = "website"
	private let emailKey = "email"
	private let phoneKey = "phone"
	private let genderKey = "gender"
	private let zipcodeKey = "zipcode"
	
	private enum ProfileEditRow: Int {
		case image = 0
		case name
		case username
		case website
		case bio
		case privateHeader
		case email
		case zipcode
		case dob
		case gender
		case count
	}
	
	@IBOutlet private weak var profileEditCollectionView: UICollectionView!
}
