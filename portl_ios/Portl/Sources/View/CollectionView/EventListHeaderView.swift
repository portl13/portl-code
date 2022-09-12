//
//  EventListHeaderView.swift
//  Portl
//
//  Created by Jeff Creed on 4/27/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import UIKit
import CSkyUtil

public class EventListHeaderView: UICollectionReusableView, Named {
    public static let name = "EventListHeaderView"
    
    func setDateLabelText(text: String) {
        dateLabel.text = text
    }
    
    @IBOutlet private weak var dateLabel: UILabel!
}
