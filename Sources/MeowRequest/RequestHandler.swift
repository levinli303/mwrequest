//
//  RequestHandler.swift
//  MeowUtils
//
//  Created by Li Linfeng on 31/10/2018.
//  Copyright © 2018 Li Linfeng. All rights reserved.
//

import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public enum RequestError: Error {
    case noResponse
    case httpEror(errorString: String)
    case urlSessionError(error: Error)
    case noData
    case decodingError(error: Error)
}

extension RequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noData:
            return NSLocalizedString("No data", comment: "")
        case .noResponse:
            return NSLocalizedString("No response", comment: "")
        case .decodingError(let error):
            return error.localizedDescription
        case .httpEror(let errorString):
            return errorString
        case .urlSessionError(let error):
            return error.localizedDescription
        }
    }
}

public class BaseRequestHandler<Output> {
    public typealias SuccessHandler = (Output) -> Void
    public typealias FailureHandler = (RequestError) -> Void
    fileprivate let successHandler: SuccessHandler?
    fileprivate let failureHandler: FailureHandler?
    fileprivate var dataTask: URLSessionDataTask?

    required init(success: SuccessHandler?, failure: FailureHandler?) {
        failureHandler = failure
        successHandler = success
    }

    public func cancel() {
        dataTask?.cancel()
    }

    fileprivate func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard error == nil else {
            failureHandler?(.urlSessionError(error: error!))
            return true
        }
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            failureHandler?(.noResponse)
            return true
        }
        guard statusCode < 400 else {
            failureHandler?(.httpEror(errorString: HTTPURLResponse.localizedString(forStatusCode: statusCode)))
            return true
        }
        guard data != nil else {
            failureHandler?(.noData)
            return true
        }
        return false
    }

    public class func get(url: String,
                          parameters: [String: String] = [:],
                          success: SuccessHandler? = nil,
                          failure: FailureHandler? = nil,
                          session: URLSession = .shared) -> Self {
        let handler = self.init(success: success, failure: failure)
        let task = session.get(from: url, parameters: parameters) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }

    public class func post(url: String,
                           parameters: [String: String] = [:],
                           success: SuccessHandler? = nil,
                           failure: FailureHandler? = nil,
                           session: URLSession = .shared) -> Self {
        let handler = self.init(success: success, failure: failure)
        let task = session.post(to: url, parameters: parameters) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }

    public class func post<T: Encodable>(url: String,
                                         json: T,
                                         encoder: JSONEncoder?,
                                         success: SuccessHandler? = nil,
                                         failure: FailureHandler? = nil,
                                         session: URLSession = .shared) -> Self {
        let handler = self.init(success: success, failure: failure)
        let task = session.post(to: url, json: json, encoder: encoder) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }

    public class func upload(url: String,
                             data: Data, key: String = "file", filename: String,
                             parameters: [String: String] = [:],
                             success: SuccessHandler? = nil,
                             failure: FailureHandler? = nil,
                             session: URLSession = .shared) -> Self {
        let handler = self.init(success: success, failure: failure)
        let task = session.upload(to: url, parameters: parameters, data: data, key: key, filename: filename) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }
}

public class EmptyRequestHandler: BaseRequestHandler<Void> {
    override func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard !super.commonHandler(data: data, response: response, error: error) else {
            return true
        }
        successHandler?(())
        return false
    }
}

public class DataRequestHandler: BaseRequestHandler<Data> {
    override func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard !super.commonHandler(data: data, response: response, error: error) else {
            return true
        }
        successHandler?(data!)
        return false
    }
}

public protocol JSONDecodable: Decodable {
    static var decoder: JSONDecoder? { get }
}

extension Array: JSONDecodable where Element: JSONDecodable {
    public static var decoder: JSONDecoder? { return Element.decoder }
}

public class JSONRequestHandler<Output>: BaseRequestHandler<Output> where Output: JSONDecodable {
    override func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard !super.commonHandler(data: data, response: response, error: error) else {
            return true
        }
        do {
            let output = try (Output.decoder ?? JSONDecoder()).decode(Output.self, from: data!)
            successHandler?(output)
            return false
        } catch let error {
            failureHandler?(.decodingError(error: error))
            return true
        }
    }
}
