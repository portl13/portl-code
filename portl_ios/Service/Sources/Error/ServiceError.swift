//
//  ServiceError.swift
//  Service
//
//  Created by Jeff Creed on 4/23/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation

public enum ServiceError: LocalizedError {
    case apiError(reason: String)
    case coreDataError(reason: String)
    case general(reason: String)
    
    public var errorDescription: String? {
        let result: String?
        switch self {
        case .apiError(let reason):
            result = reason
        case .coreDataError(let reason):
            result = reason
        case .general(let reason):
            result = reason
        }
        return result
    }
}
