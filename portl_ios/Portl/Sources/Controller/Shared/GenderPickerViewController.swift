//
//  GenderPickerViewController.swift
//  Portl
//
//  Created by Jeff Creed on 6/4/18.
//  Copyright © 2018 Portl. All rights reserved.
//

protocol GenderPickerViewControllerDelegate: class {
    func genderPickerViewController(_ genderPickerViewController: GenderPickerViewController, didSelectGender gender: String)
    func genderPickerViewControllerDidCancel(_ genderPickerViewController: GenderPickerViewController)
}

import CSkyUtil

class GenderPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, Named, StoryboardInstantiable {
    
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return GenderPickerViewController.genderTitles.count
    }
    
    // MARK: UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return GenderPickerViewController.genderTitles[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentGender = GenderPickerViewController.genderStrings[row]
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.isEnabled = currentGender != nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let gender = currentGender, gender.count > 0 else {
            return
        }
        
        pickerView.selectRow(GenderPickerViewController.genderStrings.firstIndex(of: gender)!, inComponent: 0, animated: false)
    }
    // MARK: Private
    
    @IBAction private func done(_ sender: Any) {
        delegate?.genderPickerViewController(self, didSelectGender: currentGender!)
    }
    
    @IBAction private func cancel(_ sender: Any) {
        delegate?.genderPickerViewControllerDidCancel(self)
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
    
    // MARK: Properties (DI)
    
    private var bottomSlideInTransitionFactory: BottomSlideInTransitionFactory!
    
    // MARK: Properties
    
    weak var delegate: GenderPickerViewControllerDelegate?
    var currentGender: String? {
        didSet {
            if isViewLoaded {
                doneButton.isEnabled = currentGender != nil
            }
        }
    }
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: super.preferredContentSize.width, height: GenderPickerViewController.viewHeight)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    // MARK: Properties (Private)
    
    @IBOutlet private weak var pickerView: UIPickerView!
    @IBOutlet private weak var doneButton: UIButton!
    
    // MARK: Properties (Static Constant)
    
    static let genderTitles = ["Male", "Female", "Other"]
    static let genderStrings = ["M", "F", "O"]
    static let viewHeight: CGFloat = 182.0
    
    // MARK: Properties (Named)
    
    static var name = "GenderPickerViewController"
}
