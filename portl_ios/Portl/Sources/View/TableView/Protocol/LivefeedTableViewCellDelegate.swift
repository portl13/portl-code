//
//  LivefeedTableViewCellDelegate.swift
//  Portl
//
//  Created by Jeff Creed on 3/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

protocol LivefeedTableViewCellDelegate: class {
	func livefeedTableViewCellSelectedProfile(_ livefeedTableViewCell: UITableViewCell)
	func livefeedTableViewCellSelectedEvent(_ livefeedTableViewCell: UITableViewCell)
	func livefeedTableViewCellSelectedInterested(_ livefeedTableViewCell: UITableViewCell)
	func livefeedTableViewCellSelectedGoing(_ livefeedTableViewCell: UITableViewCell)
	func livefeedTableViewCellSelectedShare(_ livefeedTableViewCell: UITableViewCell)
	func livefeedTableViewCellSelectedShowShareDetail(_ livefeedTableViewCell: UITableViewCell)
	func livefeedTableViewCell(selectedImage image: UIImage, livefeedTableViewCell: UITableViewCell)
}
