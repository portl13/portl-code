//
//  Video.swift
//  Portl
//
//  Created by Jeff Creed on 1/14/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import UIKit
import AVFoundation

struct Video: Hashable {
    
    let hlsUrl: URL
    let duration: TimeInterval
    var resumeTime: TimeInterval
    
    init(hlsUrl: URL, duration: TimeInterval, resumeTime: TimeInterval = 0) {
        self.hlsUrl = hlsUrl
        self.duration = duration
        self.resumeTime = resumeTime
    }
}

