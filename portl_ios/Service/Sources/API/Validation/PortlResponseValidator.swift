//
//  PortlResponseValidator.swift
//  Service
//
//  Created by Jeff Creed on 4/23/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import Alamofire
import APIEngine

internal class PortlResponseValidator: ResponseValidating {
    func validate(request: URLRequest?, response: HTTPURLResponse, data: Data?) -> Request.ValidationResult {
        return (200..<300).contains(response.statusCode) ? .success : .failure(ServiceError.apiError(reason: "api response error:\(response.statusCode)"))
    }
}
