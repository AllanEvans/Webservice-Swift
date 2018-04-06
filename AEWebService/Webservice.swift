//
//  Webservice.swift
//  ExchangeRates
//
//  Created by Allan Evans on 3/9/18.
//  Copyright © 2018 Aelyssum Corp. All rights reserved.
//

import Foundation

class Webservice {
    
    enum Error: Swift.Error {
        case unableToResolveURL
        case serverError(Int)
        case wrongResponseType
        case responseWasNil
        case deserializationError(Swift.Error)
    }
    
    var task: URLSessionTask!
    
    var sessionManager: URLSession {
        return URLSession.shared
    }
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case put = "PUT"
    }
    
    func get<T: Decodable>(url: URL, parameters: [String:Any]?, catch: @escaping (Swift.Error)->(), complete: @escaping (T)->()) {
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
        task = sessionManager.dataTask(with: request) {
            (data, response, error) in
            self.task = nil
            guard error == nil else {
                `throw`(error!)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                `throw`(Error.wrongResponseType)
                return
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                `throw`(Error.serverError(httpResponse.statusCode))
                return
            }
            guard let _data = data else {
                `throw`(Error.responseWasNil)
                return
            }
            do {
                let decoder = JSONDecoder()
                let responseObject: T = try decoder.decode(T.self, from: _data)
                complete(responseObject)
            } catch let error {
                `throw`(error)
            }
        }
        task.resume()
    }
    
    func post<T: Encodable>(url: URL, body: T, catch: @escaping (Swift.Error)->(), complete: @escaping ()->()) {
        request(url: url, method: .post, body: body, catch: `catch`, complete: complete)
    }

    func patch<T: Encodable>(url: URL, body: T, catch: @escaping (Swift.Error)->(), complete: @escaping ()->()) {
        request(url: url, method: .patch, body: body, catch: `catch`, complete: complete)
    }
    
    func put<T: Encodable>(url: URL, body: T, catch: @escaping (Swift.Error)->(), complete: @escaping ()->()) {
        request(url: url, method: .put, body: body, catch: `catch`, complete: complete)
    }
    
    func request<T: Encodable>(url: URL,
                               method: HTTPMethod,
                               body: T,
                               catch: @escaping (Swift.Error)->(),
                               complete: @escaping ()->()
        ) {
        let `throw` = `catch`
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(body)
        } catch let error {
            `throw`(error)
            return
        }
        task = sessionManager.dataTask(with: request) {
            (data, response, error) in
            self.task = nil
            guard error == nil else {
                `throw`(error!)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                `throw`(Error.wrongResponseType)
                return
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                `throw`(Error.serverError(httpResponse.statusCode))
                return
            }
            complete()
        }
        task.resume()
    }
    func cancel() {
        task.cancel()
        task = nil
    }
}
