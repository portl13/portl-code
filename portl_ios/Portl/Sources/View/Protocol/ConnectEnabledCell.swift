//
//  ConnectEnabledCell.swift
//  Portl
//
//  Created by Jeff Creed on 8/23/18.
//  Copyright © 2018 Portl. All rights reserved.
//

enum ConnectButtonStyle {
	case connected
	case notConnected
	case sentPending
	case receivedPending
}

protocol ConnectEnabledCellDelegate: class {
	func connectEnabledCellDidSelectConnect(_ connectEnabledCell: ConnectEnabledCell)
	func connectEnabledCellDidSelectDisconnect(_ connectEnabledCell: ConnectEnabledCell)
	func connectEnabledCellDidSelectCancel(_ connectEnabledCell: ConnectEnabledCell)
	func connectEnabledCellDidSelectApprove(_ connectEnabledCell: ConnectEnabledCell)
	func connectEnabledCellDidSelectDecline(_ connectEnabledCell: ConnectEnabledCell)
}

protocol ConnectEnabledCell: class {
	func connect(_ sender: Any?)
	func cancelSent(_ sender: Any?)
	func approve(_ sender: Any?)
	func disconnect(_ sender: Any?)
	func decline(_ sender: Any?)
}
