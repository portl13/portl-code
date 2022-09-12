//
//  EmptyCategoriesCollectionViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 6/11/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

protocol EmptyCategoriesCollectionViewCellDelegate: class {
	func emptyCategoriesCollectionViewCellDidSelectManageCategories(_ emptyCategoriesCollectionViewCell: EmptyCategoriesCollectionViewCell)
}

class EmptyCategoriesCollectionViewCell: UICollectionViewCell, Named {
	
	// MARK: Action
	
	@IBAction private func onManageCategoriesPressed(_ sender: Any) {
		delegate?.emptyCategoriesCollectionViewCellDidSelectManageCategories(self)
	}
	
	// MARK: Config
	
	func config(forCategoryNames categoryNames: [String]) {
		let text = EmptyCategoriesCollectionViewCell.getCategoriesListString(fromCategoryNames: categoryNames)
		
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .center
		paragraph.lineBreakMode = .byWordWrapping
	
		let categoriesString = NSMutableAttributedString(string: text, textStyle: .body)
		categoriesString.addAttributes([.paragraphStyle: paragraph], range: NSRange(location: 0, length: categoriesString.length))
		categoryNamesLabel.attributedText = categoriesString
	}
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		manageCategoriesButton.layer.cornerRadius = 4
		manageCategoriesButton.layer.borderWidth = 1
		manageCategoriesButton.layer.borderColor = PaletteColor.light1.cgColor
		let manageString = NSAttributedString(string: EmptyCategoriesCollectionViewCell.manageText, textStyle: .body)
		manageCategoriesButton.setAttributedTitle(manageString, for: .normal)
		
		let lookingString = NSAttributedString(string: EmptyCategoriesCollectionViewCell.lookingText, textStyle: .h3Bold)
		lookingLabel.attributedText = lookingString
	}
	
	// MARK: Sizing
	
	private static func getCategoriesListString(fromCategoryNames categoryNames: [String]) -> String {
		var categoriesList: String?
		var categoryNoun: String?
		
		if categoryNames.count > 1 {
			categoriesList = categoryNames.dropLast().joined(separator: ", ") + ", or \(categoryNames.last!)"
			categoryNoun = EmptyCategoriesCollectionViewCell.categoryPlural
		} else {
			categoriesList = categoryNames.first
			categoryNoun = EmptyCategoriesCollectionViewCell.categorySingular
		}
		
		return String(format: EmptyCategoriesCollectionViewCell.categoriesFormat, categoriesList!, categoryNoun!)
	}
	
	static func getSizeForCell(usingWidth width: CGFloat, andCategoryNames categoryNames: [String]) -> CGSize {
		let constraintRect = CGSize(width: dynamicLabelWidth, height: .greatestFiniteMagnitude)
		let text = getCategoriesListString(fromCategoryNames: categoryNames)
		let boundingRect = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0)], context: nil)
		
		return CGSize(width: width, height: boundingRect.height + aboveDynamicLabel + belowDynamicLabel)
	}
	
	// MARK: Properties
	
	weak var delegate: EmptyCategoriesCollectionViewCellDelegate?
	
	// MARK: Properties (Private)
	
	@IBOutlet private weak var lookingLabel: UILabel!
	@IBOutlet private weak var categoryNamesLabel: UILabel!
	@IBOutlet private weak var manageCategoriesButton: UIButton!
	
	// MARK: Properties (Private Static)
	
	private static let lookingText = "LOOKING FOR MORE?"
	private static let categoriesFormat = "There are no events in the %@ %@."
	private static let categorySingular = "category"
	private static let categoryPlural = "categories"
	private static let manageText = "Manage Categories"
	private static let aboveDynamicLabel: CGFloat = 44.0
	private static let belowDynamicLabel: CGFloat = 79.0
	private static let dynamicLabelWidth: CGFloat = 256.0
	
	// MARK: Properties (Named)
	
	static let name = "EmptyCategoriesCollectionViewCell"
}
