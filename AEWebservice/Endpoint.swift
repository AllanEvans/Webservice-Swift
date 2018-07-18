//
//  Endpoint.swift
//  AEWebService
//
//  Created by Allan Evans on 5/29/18.
//  Copyright © 2018 AllanEvans. All rights reserved.
//

import Foundation

public protocol Endpoint {
    
    var sessionManager: URLSession { get }
    var url: URL { get }
    var method: Webservice.HTTPMethod { get }
    var queryParameters: [String: Any]? { get }
    
}

public extension Endpoint {
    
    var sessionManager: URLSession {
        return URLSession.shared
    }
    
}

public extension Webservice {
    
    public func request<T: Encodable>(_ endpoint: Endpoint,
                                      body: T,
                 catch throw: @escaping (Swift.Error)->(),
                 complete: @escaping ()->()
        ) {
        guard endpoint.method != .get else {
            `throw`(Error.wrongResponseType)
            return
        }
        request(url: endpoint.url, method: endpoint.method, body: body, catch: `throw`, complete: complete)
    }

    public func get<T: Decodable>(_ endpoint: Endpoint,
                               catch throw: @escaping (Swift.Error)->(),
                               complete: @escaping (T)->()
        ) {
        get(url: endpoint.url, parameters: endpoint.queryParameters, sessionManager: endpoint.sessionManager, catch: `throw`, complete: complete)
    }
    
}
