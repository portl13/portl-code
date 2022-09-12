//
//  OptionalSignUpViewController.swift
//  Portl
//
//  Created by Jeff Creed on 8/1/18.
//  Copyright © 2018 Portl. All rights reserved.
//

@objc protocol OptionalSignUpViewControllerDelegate: class {
	func optionalSignUpViewControllerDidFinish(_ optionalSignUpViewController: OptionalSignUpViewController)
}

import CSkyUtil

class OptionalSignUpViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
	
	
	// MARK: UIPickerViewDataSource
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return genderValues.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return genderTitles[row]
	}
	
	// MARK: UIPickerViewDelegate
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		genderTextField.text = genderTitles[row]
	}
	
	// MARK: UITextFieldDelegate
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		currentTextField = textField
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if let nextResponder = textField.superview?.viewWithTag(textField.tag + 1) {
			nextResponder.becomeFirstResponder()
		} else {
			textField.resignFirstResponder()
		}
		return false
	}
	
	// MARK: Private
	
	@objc private func datePickerDidSelectDate(picker: UIDatePicker) {
		birthdayTextField.text = birthdayDisplayDateFormatter.string(from: picker.date)
	}
	
	@IBAction private func skipForNow(sender: Any?) {
		delegate?.optionalSignUpViewControllerDidFinish(self)
	}
	
	@IBAction private func saveOptionalValues(sender: Any?) {
		profile.updateOptionalInformationFromSignUp(zipcode: zipcodeTextField.text,
													firstName: firstNameTextField.text,
													lastName: lastNameTextField.text,
													birthDate: birthdayDateFormatter.string(from: datePicker.date),
													gender: genderValues[genderPicker.selectedRow(inComponent: 0)]) { [unowned self] (error) in
														guard error == nil else {
															let alert = UIAlertController(title: "Error", message: error!.customizedErrorMessage, preferredStyle: .alert)
															alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
															self.present(alert, animated: true, completion: nil)
															return
														}
														self.delegate?.optionalSignUpViewControllerDidFinish(self)
		}
	}
	
	@IBAction private func dismissKeyboard(sender: Any?) {
		UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	}
	
	@objc private func inputViewDone(sender: Any?) {
		let _ = textFieldShouldReturn(currentTextField!)
	}
	
	// MARK: Notifications (Keyboard)
	
	@objc private func keyboardWillShow(notification: NSNotification) {
		let info = notification.userInfo
		let kbSize = (info![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect).size
		UIView.animate(withDuration: 0.2) { [unowned self] in
			self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
			self.view.layoutIfNeeded()
		}
		dismissKeyboardButton.isHidden = false
	}
	
	@objc private func keyboardWillDismiss(notification: NSNotification) {
		dismissKeyboardButton.isHidden = true
		
		UIView.animate(withDuration: 0.2) { [unowned self] in
			self.scrollView.contentInset = UIEdgeInsets.zero
			self.view.layoutIfNeeded()
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if #available(iOS 13.0, *) {
			overrideUserInterfaceStyle = .light
		}
		
		let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(inputViewDone))
		let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(inputViewDone))
		let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

		let nextToolbar = UIToolbar()
		nextToolbar.barStyle = .default
		nextToolbar.setItems([space, nextButton], animated: false)
		nextToolbar.isUserInteractionEnabled = true
		nextToolbar.sizeToFit()
		
		let doneToolbar = UIToolbar()
		doneToolbar.barStyle = .default
		doneToolbar.setItems([space, doneButton], animated: false)
		doneToolbar.isUserInteractionEnabled = true
		doneToolbar.sizeToFit()

		birthdayTextField.inputView = datePicker
		birthdayTextField.inputAccessoryView = nextToolbar
		
		genderTextField.inputView = genderPicker
		genderTextField.inputAccessoryView = doneToolbar
		
		zipcodeTextField.inputAccessoryView = nextToolbar
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDismiss), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		datePicker = UIDatePicker()
		datePicker.datePickerMode = .date
		datePicker.maximumDate = Calendar.current.date(byAdding: .year, value: -13, to: Date())
		datePicker.setValue(false, forKey: "highlightsToday")
		datePicker.setValue(PaletteColor.dark1.uiColor, forKeyPath: "textColor")
		datePicker.addTarget(self, action: #selector(datePickerDidSelectDate), for: .valueChanged)
		
		genderPicker = UIPickerView()
		genderPicker.setTintColor(.dark1)
		genderPicker.setValue(PaletteColor.dark1.uiColor, forKeyPath: "textColor")
		genderPicker.dataSource = self
		genderPicker.delegate = self
		
		Injector.root?.inject(into: inject)
	}
	
	private func inject(birthdayDateFormatter: BirthdayDateFormatterQualifier, birthdayDisplayDateFormatter: NoTimeDateFormatterQualifier, profile: OldProfileService) {
		self.birthdayDateFormatter = birthdayDateFormatter.value
		self.birthdayDisplayDateFormatter = birthdayDisplayDateFormatter.value
		self.profile = profile
	}
	
	// MARK: Properties
	
	@objc weak var delegate: OptionalSignUpViewControllerDelegate?
	
	// MARK: Properties (DI)
	
	private var birthdayDisplayDateFormatter: DateFormatter!
	private var birthdayDateFormatter: DateFormatter!
	private var profile: OldProfileService!
	
	// MARK: Properties (Private)
	
	private var datePicker: UIDatePicker!
	private var genderPicker: UIPickerView!
	private var genderValues = ["", "M", "F", "O"]
	private var genderTitles = ["", "Male", "Female", "Other"]
	private var currentTextField: UITextField?
	
	@IBOutlet private weak var zipcodeTextField: UITextField!
	@IBOutlet private weak var firstNameTextField: UITextField!
	@IBOutlet private weak var lastNameTextField: UITextField!
	@IBOutlet private weak var birthdayTextField: UITextField!
	@IBOutlet private weak var genderTextField: UITextField!
	@IBOutlet private weak var scrollView: UIScrollView!
	@IBOutlet private weak var dismissKeyboardButton: UIButton!
}
