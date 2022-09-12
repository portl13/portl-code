//
//  EventCategoryCollectionViewCellDelegate.swift
//  Portl
//
//  Created by Jeff Creed on 4/6/18.
//  Copyright © 2018 Portl. All rights reserved.
//

protocol EventCategoryCollectionViewCellDelegate: class {
    func eventCategoryCollectionViewCell(_ eventCategoryCollectionViewCell: EventCategoryCollectionViewCell, didSelectShowAllForCategory category: PortlCategory)
    func eventCategoryCollectionViewCell(_ eventCategoryCollectionViewCell: EventCategoryCollectionViewCell, didSelectEvent event: PortlEvent, inCategory category: PortlCategory)
}
