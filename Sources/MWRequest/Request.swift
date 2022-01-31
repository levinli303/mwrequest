//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public extension URLSession {
    func post(to url: String, parameters: [String: String], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.setPostParameters(parameters)
        let task = dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }

    func post<T: Encodable>(to url: String, json: T, encoder: JSONEncoder?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.setPostParametersJson(json, encoder: encoder)
        let task = dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }

    func upload(to url: String, parameters: [String: String], data: Data, key: String, filename: String,  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.setUploadParameters(parameters, data: data, key: key, filename: filename)
        let task = dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }

    func get(from url: String, parameters: [String: String], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let suffix = parameters.urlQueryEncoded
        let url = URL(string: (suffix.count > 0 ? "\(url)?\(suffix)" : url))
        let task = dataTask(with: url!, completionHandler: completionHandler)
        task.resume()
        return task
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 15.0, macOS 12.0, *)
public extension URLSession {
    func post(to url: String, parameters: [String: String]) async throws -> (Data, URLResponse) {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.setPostParameters(parameters)
        return try await data(for: request, delegate: nil)
    }

    func post<T: Encodable>(to url: String, json: T, encoder: JSONEncoder?) async throws -> (Data, URLResponse) {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.setPostParametersJson(json, encoder: encoder)
        return try await data(for: request, delegate: nil)
    }

    func upload(to url: String, parameters: [String: String], data: Data, key: String, filename: String) async throws -> (Data, URLResponse) {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.setUploadParameters(parameters, data: data, key: key, filename: filename)
        return try await self.data(for: request, delegate: nil)
    }

    func get(from url: String, parameters: [String: String]) async throws -> (Data, URLResponse) {
        let suffix = parameters.urlQueryEncoded
        let url = URL(string: (suffix.count > 0 ? "\(url)?\(suffix)" : url))
        return try await data(for: URLRequest(url: url!), delegate: nil)
    }
}
#endif

fileprivate extension Dictionary where Key == String, Value == String {
    var urlQueryEncoded: String {
        return self.map {"\($0)=\($1)"}.joined(separator: "&").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
}

fileprivate extension URLRequest {
    mutating func setPostParametersJson<T: Encodable>(_ encodable: T, encoder: JSONEncoder?) {
        httpMethod = "POST"
        setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        httpBody = try? (encoder ?? JSONEncoder()).encode(encodable)
    }

    mutating func setPostParameters(_ parameters: [String: String]) {
        httpMethod = "POST"
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        httpBody = parameters.urlQueryEncoded.data(using: String.Encoding.utf8)
    }

    mutating func setUploadParameters(_ parameters: [String: String], data: Data, key: String, filename: String) {
        let boundary = "Boundary-\(UUID().uuidString)"
        let mimeType = "application/octet-stream"

        /* Create upload body */
        var body = Data()

        func appendString(_ string: String) {
            let data = string.data(using: .utf8)
            body.append(data!)
        }

        /* Key/value pairs */
        let boundaryPrefix = "--\(boundary)\r\n"
        for (key, value) in parameters {
            appendString(boundaryPrefix)
            appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            appendString("\(value)\r\n")
        }
        /* File information */
        appendString(boundaryPrefix)
        appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(mimeType)\r\n\r\n")
        /* File data */
        body.append(data)
        appendString("\r\n")
        appendString("--".appending(boundary.appending("--")))

        httpMethod = "POST"
        httpBody = body
        setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    }
}

fileprivate extension CharacterSet {
    static var allowedURLCharacterSet: CharacterSet {
        return .urlQueryAllowed
    }
}
