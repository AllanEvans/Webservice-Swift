//
//  Webservice.swift
//  ExchangeRates
//
//  Created by Allan Evans on 3/9/18.
//  Copyright © 2018 Aelyssum Corp. All rights reserved.
//

import Foundation

public class Webservice {
    
    public enum Error: Swift.Error {
        case unableToResolveURL
        case serverError(Int)
        case wrongResponseType
        case responseWasNil
        case postBodyWasNil
        case deserializationError(Swift.Error)
    }
    
    var task: URLSessionTask!
    
    public enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case put = "PUT"
    }
    
    public func get<T: Decodable>(url: URL, parameters: [String:Any]?, sessionManager: URLSession = URLSession.shared, catch: @escaping (Swift.Error)->(), complete: @escaping (T)->()) {
        let `throw` = `catch`
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            `throw`(Error.unableToResolveURL)
            return
        }
        if let _parameters = parameters, !_parameters.isEmpty {
            var queryParameters = [URLQueryItem]()
            for (key,value) in _parameters {
                queryParameters.append(URLQueryItem(name: key, value: String(describing: value)))
            }
            urlComponents.queryItems = queryParameters
        }
        guard let fullyFormedUrl = urlComponents.url else {
            `throw`(Error.unableToResolveURL)
            return
        }
        var request = URLRequest(url: fullyFormedUrl)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        task = sessionManager.dataTask(with: request) {
            (data, response, error) in
            self.task = nil
            do {
               try self.validate(response: response, error: error)
            } catch let error {
                `throw`(error)
                return
            }
            do {
                let responseObject: T = try self.decode(data)
                complete(responseObject)
            } catch let error {
                `throw`(error)
            }
        }
        task.resume()
    }
    
    public func post<T: Encodable>(url: URL, body: T, sessionManager: URLSession = URLSession.shared, catch: @escaping (Swift.Error)->(), complete: @escaping ()->()) {
        request(url: url, method: .post, body: body, catch: `catch`, complete: complete)
    }

    public func patch<T: Encodable>(url: URL, body: T, sessionManager: URLSession = URLSession.shared, catch: @escaping (Swift.Error)->(), complete: @escaping ()->()) {
        request(url: url, method: .patch, body: body, catch: `catch`, complete: complete)
    }
    
    public func put<T: Encodable>(url: URL,
                           body: T,
                           sessionManager: URLSession = URLSession.shared,
                           catch: @escaping (Swift.Error)->(),
                           complete: @escaping ()->()
        ) {
        request(url: url, method: .put, body: body, catch: `catch`, complete: complete)
    }
    
    func request<T: Encodable>(url: URL,
                               method: HTTPMethod,
                               body: T,
                               sessionManager: URLSession = URLSession.shared,
                               catch throw: @escaping (Swift.Error)->(),
                               complete: @escaping ()->()
        ) {
        let encoder = JSONEncoder()
        do {
            let httpBody = try encoder.encode(body)
            request(url: url, method: method, body: httpBody, catch: `throw`, complete: complete)
        } catch let error {
            `throw`(error)
            return
        }
    }

    func request(url: URL,
                 method: HTTPMethod,
                 body: Data,
                 sessionManager: URLSession = URLSession.shared,
                 catch: @escaping (Swift.Error)->(),
                 complete: @escaping ()->()
        ) {
        let `throw` = `catch`
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        task = sessionManager.dataTask(with: request) {
            (data, response, error) in
            self.task = nil
            do {
                try self.validate(response: response, error: error)
                complete()
            } catch let error {
                `throw`(error)
            }
        }
        task.resume()
    }

    func decode<T: Decodable>(_ data: Data?) throws -> T {
        guard let _data = data else {
            throw Error.responseWasNil
        }
        do {
            let decoder = JSONDecoder()
            let responseObject: T = try decoder.decode(T.self, from: _data)
            return  responseObject
        } catch let error {
            throw error
        }

    }
    
    func validate(response: URLResponse?, error: Swift.Error?) throws -> () {
        guard error == nil else {
            throw error!
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.wrongResponseType
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw Error.serverError(httpResponse.statusCode)
        }
    }
    
    public func cancel() {
        task.cancel()
        task = nil
    }
}
