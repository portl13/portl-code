//
//  InterestsSelectViewController.swift
//  Portl
//
//  Created by Jeff Creed on 7/5/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreData
import Service
import CSkyUtil

protocol InterestsSelectViewControllerDelegate: class {
    func interestsUpdated(to updated: Array<Dictionary<PortlCategory, Bool>>)
}

class InterestsSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    // MARK: NSFetchedResultsController
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        configureCategories()
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mutableInterests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = mutableInterests[indexPath.row].keys.first!
        let selected = mutableInterests[indexPath.row].values.first!
        
        let cell = tableView.dequeue(CategorySelectTableViewCell.self, for: indexPath)
        cell.configure(withCategory: category, andSelected: selected)
		cell.shouldShowHR(indexPath.row < mutableInterests.count - 1)
		
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let catDict = mutableInterests[indexPath.row].first!
        if catDict.value && selectedCount() == minimumRequiredInterests {
            presentMinimumSelectionAlert()
        } else {
            mutableInterests[indexPath.row] = [catDict.key: !catDict.value]
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.deselectRow(at: indexPath, animated: true)
            doneButton.isEnabled = selectionChanged()
        }
    }
        
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        mutableInterests.insert(mutableInterests.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
        doneButton?.isEnabled = selectionChanged()
    }
    
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(CategorySelectTableViewCell.self)
        
        let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
        backItem.tintColor = .white
        navigationItem.leftBarButtonItem = backItem
        
        self.navigationItem.rightBarButtonItem = doneButton
        doneButton.isEnabled = false
        
        categoriesResultsController = portlService.fetchedResultsControllerForPortlCategories(delegate: self)
        
        tableView.allowsSelectionDuringEditing = true
        tableView.isEditing = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureCategories()
    }
    
    // MARK: Private
    
    @objc private func onDone() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        spinner.startAnimating()
        delegate?.interestsUpdated(to: mutableInterests)
    }
    
    @objc private func onBack() {
        if selectionChanged() {
            let controller = UIAlertController(title: nil, message: "Save your changes?", preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Yes", style: .default, handler: {[unowned self] (action) in
                self.delegate?.interestsUpdated(to: self.mutableInterests)
            }))
            controller.addAction(UIAlertAction(title: "No", style: .cancel, handler: {[unowned self] (action) in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(controller, animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func configureCategories() {
        if initialInterests.count > 0 {
            let sortedResults = initialInterests.compactMap { (cat) -> Dictionary<PortlCategory, Bool>? in
                if let portlCatIdx = categoriesResultsController?.fetchedObjects?.firstIndex(of: cat.first!.key), let portlCat = categoriesResultsController?.fetchedObjects?[portlCatIdx] {
                    return [portlCat : cat.first!.value]
                } else {
                    return nil
                }
            }
            mutableInterests = sortedResults
        } else {
            mutableInterests = categoriesResultsController?.fetchedObjects?.map { [$0: $0.defaultSelected] } ?? [[:]]
        }
    }
    
    private func selectionChanged() -> Bool {
        return initialInterests.count != mutableInterests.count ||
        !initialInterests.elementsEqual(mutableInterests) { (dict1, dict2) -> Bool in
            return dict1.first?.key == dict2.first?.key && dict1.first?.value == dict2.first?.value
        }
    }
    
    private func selectedCount() -> Int {
        return mutableInterests.reduce(0, { (result, interest) -> Int in
            return result + (interest.first!.value ? 1 : 0)
        })
    }
    
    func presentMinimumSelectionAlert() {
        let controller = UIAlertController(title: nil, message: "You must have at least \(minimumRequiredInterests) categories selected.", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(controller, animated: true, completion: nil)
    }
    
    // MARK: Init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Injector.root!.inject(into: inject)
        
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        doneButton.tintColor = .white
    }
    
    private func inject(portlService: PortlDataProviding) {
        self.portlService = portlService
    }
    
    // MARK: Properties
    
    var initialInterests = Array<Dictionary<PortlCategory, Bool>>()
    var minimumRequiredInterests: Int = 3
    weak var delegate: InterestsSelectViewControllerDelegate?
    
    // MARK: Properties (Injected)
    
    private var portlService: PortlDataProviding!
    
    // MARK: Properties (Private)
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    private var categoriesResultsController: NSFetchedResultsController<PortlCategory>?
    private var mutableInterests = Array<Dictionary<PortlCategory, Bool>>()
    private var doneButton: UIBarButtonItem!
}
