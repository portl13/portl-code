//
//  EventCategoryCollectionViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 4/5/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import UIKit
import Service
import CoreData
import CSkyUtil
import RxSwift

class EventCategoryCollectionViewCell: UICollectionViewCell, Named, EventCategoryControllerDelegate {
    override func awakeFromNib() {
        super.awakeFromNib()
		categoryCollectionView.contentInset = UIEdgeInsets(top: 0.0, left: EventCategoryCollectionViewCell.collectionViewLeftInset, bottom: 0.0, right: 0.0)
    }
    
    // MARK: Private (IBAction)
    
    @IBAction private func initiateShowAllTransition(_ sender: Any) {
        delegate?.eventCategoryCollectionViewCell(self, didSelectShowAllForCategory: category!)
    }
    
    func initiateEventDetailTransition(withEvent event:PortlEvent) {
        delegate?.eventCategoryCollectionViewCell(self, didSelectEvent: event, inCategory: category!)
    }
    
    // MARK: Properties (Configure)
    
    func updateWith(category: PortlCategory, eventCategoryController: EventCategoryController?) {
		self.category = category
        categoryLabel.attributedText = NSAttributedString(string: category.display, textStyle: .h3Bold)

        if let eventCategoryController = eventCategoryController {
            eventCategoryController.collectionView = categoryCollectionView
            eventCategoryController.delegate = self
            
            loadingView.isHidden = true
			activityIndicator.stopAnimating()
            showAllButton.isHidden = !eventCategoryController.hasItems
			if categoryCollectionView.numberOfItems(inSection: 0) > 0 {
				categoryCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
			}
        }
        else {
            categoryCollectionView.dataSource = nil
            categoryCollectionView.delegate = nil
            categoryCollectionView.reloadData()
            loadingView.isHidden = false
			activityIndicator.startAnimating()
            showAllButton.isHidden = true
        }
    }
	
    // MARK: Properties
    
    weak var delegate: EventCategoryCollectionViewCellDelegate?
    
    // MARK: Properties (Private)
    
    private var category: PortlCategory?
    
    @IBOutlet private weak var loadingView: UIView!
	@IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var categoryCollectionView: UICollectionView!
    @IBOutlet private weak var showAllButton: UIButton!
    
    // MARK: Properties (Private Static Constant)
    
    private static let collectionViewLeftInset: CGFloat = 10.0
    
    // MARK: Properties (Named)
    
    public static let name = "EventCategoryCollectionViewCell"
    
    public static let emptyHeight: CGFloat = 63.0
}
