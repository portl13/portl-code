//
//  ProfileEditPictureCollectionViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 6/2/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import SDWebImage

class ProfileEditPictureCollectionViewCell: UICollectionViewCell, Named {
    func configure(withImageURL imageURL: String?) {
		let placeholderImage = UIImage(named: "img_profile_placeholder")!
		
        if let imageURL = imageURL {
			imageView.sd_setImage(with: URL(string: imageURL)) {[unowned self] (_, error, _, _) in
				guard error == nil || error!.localizedDescription.contains("2002") else {
					self.imageView.sd_setImage(with: nil, placeholderImage: placeholderImage, options: [], context: nil)
					return
				}
			}
        } else {
            imageView.sd_setImage(with: nil, placeholderImage: placeholderImage, options: [], context: nil)
        }
    }
	
	// MARK: Life Cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		imageView.sd_imageIndicator = SDWebImageActivityIndicator.white
	}
	
    // MARK: Properties (Named)
    
    static var name = "ProfileEditPictureCollectionViewCell"
    
    // MARK: Properties (Private)
    
    @IBOutlet private weak var imageView: UIImageView!
    
    // MARK: Static
    
    static func heightForCell() -> CGFloat {
        return 159.0
    }
}
