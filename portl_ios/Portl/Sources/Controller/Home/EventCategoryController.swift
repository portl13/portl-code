//
//  EventCategoryController.swift
//  Portl
//
//  Created by Jeff Creed on 4/24/18.
//  Copyright © 2018 Portl. All rights reserved.
//


import CoreData
import CSkyUtil
import Service
import UIKit


class EventCategoryController: CollectionController<EventSearchItem> {
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(EventCollectionViewCell.self, for: indexPath)
        
        cell.setEventItem(fetchedResultsController!.object(at: indexPath))
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.initiateEventDetailTransition(withEvent: fetchedResultsController!.object(at: indexPath).event)
    }
    
    override func configureCollectionView() {
        collectionView!.registerNib(EventCollectionViewCell.self)
        
        collectionView!.dataSource = self
        collectionView!.delegate = self
    }
    
    weak var delegate: EventCategoryControllerDelegate?
}
