//
//  CollectionController.swift
//  Portl
//
//  Created by Jeff Creed on 5/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreData

class CollectionController<T: NSManagedObject>: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout  {
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.reloadData()
    }
    
    // MARK: UICollectionViewDatasource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("Override in subclass")
    }
    
    // MARK: UICollectionViewCellDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        fatalError("Override in subclass")
    }
    
    // MARK: Private
    
    func configureCollectionView() {
        fatalError("Override in subclass")
    }
    
    // MARK: Properties
    
    var collectionView: UICollectionView? {
        didSet {
            configureCollectionView()
        }
    }
    
    var hasItems: Bool {
        get {
            return (fetchedResultsController?.sections?.first?.numberOfObjects ?? 0) > 0
        }
    }
    
    var items: [T]? {
        get {
            return fetchedResultsController?.fetchedObjects
        }
    }
    
    // MARK: Properties
    
    var fetchedResultsController: NSFetchedResultsController<T>?
}
