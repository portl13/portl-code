//
//  DatePickerViewController.swift
//  Portl
//
//  Created by Jeff Creed on 8/1/18.
//  Copyright © 2018 Portl. All rights reserved.
//

protocol DatePickerViewControllerDelegate: class {
	func datePickerViewController(_ datePickerViewController: DatePickerViewController, didSelectDate date: Date)
	func datePickerViewControllerDidCancel(_ datePickerViewController: DatePickerViewController)
}


import CSkyUtil

class DatePickerViewController: UIViewController, Named, StoryboardInstantiable {
	
	// MARK: Private
	
	@IBAction private func dateSelected(sender: UIDatePicker) {
		selectedDate = sender.date
	}
	
	@IBAction private func done() {
		delegate?.datePickerViewController(self, didSelectDate: selectedDate!)
	}
	
	@IBAction private func cancel() {
		delegate?.datePickerViewControllerDidCancel(self)
	}
	
	// MARK: View Life Cycle
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let id = initialDate {
			datePicker.date = id
		}
		
		datePicker.maximumDate = maxDate
		doneButton.isEnabled = selectedDate != nil && selectedDate != initialDate
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root?.inject(into: inject)
		modalPresentationStyle = .overCurrentContext
		transitioningDelegate = bottomSlideInTransitionFactory
	}
	
	private func inject(bottomSlideInTransitionFactory: BottomSlideInTransitionFactory) {
		self.bottomSlideInTransitionFactory = bottomSlideInTransitionFactory
	}
	
	// MARK: Properties
	
	var initialDate: Date?
	var maxDate: Date? = Date()
	
	weak var delegate: DatePickerViewControllerDelegate?
	
	// MARK: Properties (DI)
	
	private var bottomSlideInTransitionFactory: BottomSlideInTransitionFactory!

	// MARK: Properties (Private)
	
	@IBOutlet private weak var datePicker: UIDatePicker!
	@IBOutlet private weak var doneButton: UIButton!
	
	private var selectedDate: Date? {
		didSet {
			doneButton.isEnabled = selectedDate != nil && selectedDate != initialDate
		}
	}
	
	// MARK: Properties (Named)
	
	static var name = "DatePickerViewController"
}
