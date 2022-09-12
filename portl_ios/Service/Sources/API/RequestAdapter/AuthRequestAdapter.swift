//
//  AuthRequestAdapter.swift
//  Service
//
//  Created by Jeff Creed on 4/23/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import CSkyUtil
import Alamofire

internal class AuthRequestAdapter: RequestAdapter {
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        urlRequest.setValue("Basic \(authKey)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
    
    private let authKey = "aU9TdjI6OWM1YTczYmItMDMxMy00ZDI2LThhYzItZGZmNDc1YWRmNGIz"
}
