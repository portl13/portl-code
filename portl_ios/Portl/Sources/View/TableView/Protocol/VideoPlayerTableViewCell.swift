//
//  VideoPlayerTableViewCell.swift
//  Portl
//
//  Created by Jeff Creed on 1/14/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import Foundation

protocol VideoPlayerProvidingCell {
	var videoDelegate: VideoPlayerProvidingCellDelegate?  { get set }
}

protocol VideoPlayerProvidingCellDelegate: class {
	func videoPlayerProvidingCellTapped(_ cell: VideoPlayerProvidingCell)
}
