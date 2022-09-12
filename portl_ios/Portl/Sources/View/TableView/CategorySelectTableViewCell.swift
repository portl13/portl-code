//
//  CategorySelectCell.swift
//  Portl
//
//  Created by Jeff Creed on 7/5/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil

class CategorySelectTableViewCell: UITableViewCell, Named {
    func configure(withCategory category: PortlCategory, andSelected selected: Bool) {
        titleLabel.text = category.display
        iconImageView.image = UIImage(named: UIService.iconNameForCategory(category: category))
		checkImageView.image = selected ? checkMarkImage : noCheckMarkImage
    }
	
	func shouldShowHR(_ show: Bool) {
		horizontalRule.isHidden = !show
	}
	
    // MARK: Properties (Private)
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var checkImageView: UIImageView!
	@IBOutlet private weak var horizontalRule: UIView!
	
	private var checkMarkImage = UIImage(named: "icon_selection_check_checked")
	private var noCheckMarkImage = UIImage(named: "icon_selection_check_unchecked")
	
    // MARK: Properties (Named)
    
    static var name = "CategorySelectTableViewCell"
}
