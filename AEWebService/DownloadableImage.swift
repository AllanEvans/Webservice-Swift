//
//  DownloadableImage.swift
//  AEWebService
//
//  Created by Allan Evans on 5/27/18.
//  Copyright © 2018 AllanEvans. All rights reserved.
//

import Foundation

class DownloadableImage {

    enum Error: Swift.Error {
        case invalidURL
        case nilResponse
        case noImageAtURL
    }
    private var url: URL
    private var image: UIImage?
    private var task: URLSessionTask?
    
    init(urlString: String) throws {
        guard let _url = URL(string: urlString) else {
            throw Error.invalidURL
        }
        self.url = _url
    }
    
    func getImage(catch throw: @escaping (Swift.Error) -> (), complete: @escaping (UIImage) -> ()) {
        guard image == nil else {
            complete(image!)
            return
        }
        task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                `throw`(error!)
                return
            }
            guard let imageData = data else {
                `throw`(Error.nilResponse)
                return
            }
            guard let _image = UIImage(data: imageData) else {
                `throw`(Error.noImageAtURL)
                return
            }
            self.image = _image
            self.task = nil
            complete(_image)
        }
    }
    
    func cancel() {
        task?.cancel()
    }
    
}
