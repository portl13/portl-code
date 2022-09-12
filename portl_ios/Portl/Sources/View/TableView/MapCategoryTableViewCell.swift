//
//  MapCategoryTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 4/17/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import UIKit
import CSkyUtil

class MapCategoryTableViewCell: UITableViewCell, Named {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetCell()
    }
    
    // MARK: Private
    
    private func resetCell() {
        categoryImageView.image = nil
        categoryLabel.text = ""
    }
    
    // MARK: Properties
    
	func configureWithCategory(_ category: String, displayName: String, showOnMap: Bool) {
        checkboxImageView.image = showOnMap ? #imageLiteral(resourceName: "icon_selection_check_checked") : #imageLiteral(resourceName: "icon_selection_check_unchecked")
        
        if let image = UIImage(named: UIService.iconNameForLowercaseCategoryName(categoryName: category.lowercased())) {
            categoryImageView.image = image
        } else {
            categoryImageView.image = UIImage(named: "icon_cat_other_25")
        }
        
        categoryLabel.text = displayName.capitalized
    }
	
	func shouldShowHR(_ show: Bool) {
		horizontalRule.isHidden = !show
	}
	
    // MARK: Properties (Static)
    
    public static var name: String = "MapCategoryTableViewCell"
    
    // MARK: Properties (Private)
    
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var categoryImageView: UIImageView!
    @IBOutlet private weak var checkboxImageView: UIImageView!
	@IBOutlet private weak var horizontalRule: UIView!
}
