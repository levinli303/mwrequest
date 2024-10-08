//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum RequestError: Error {
    case noResponse
    case urlError
    case httpError(statusCode: Int, errorString: String, responseBody: Data)
    case urlSessionError(error: Error)
    case decodingError(error: Error)
    case unknown
}

extension RequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .urlError:
            return NSLocalizedString("Incorrect URL", comment: "")
        case .noResponse:
            return NSLocalizedString("No response", comment: "")
        case .decodingError(let error):
            return error.localizedDescription
        case .httpError(_, let errorString, _):
            return errorString
        case .urlSessionError(let error):
            return error.localizedDescription
        case .unknown:
            return NSLocalizedString("Unknown error", comment: "")
        }
    }
}

public class BaseRequestHandler<Output> {
    private let successHandler: (@Sendable (Output) -> Void)?
    private let failureHandler: (@Sendable (RequestError) -> Void)?
    private var dataTask: URLSessionDataTask?

    private var savedResult: Result<Output, RequestError>?
    private var semaphore: DispatchSemaphore?

    required init(success: (@Sendable (Output) -> Void)?, failure: (@Sendable (RequestError) -> Void)?) {
        failureHandler = failure
        successHandler = success
    }

    public func cancel() {
        dataTask?.cancel()
    }

    public func get() throws -> Output {
        if let result = savedResult {
            switch result {
            case .success(let output):
                return output
            case .failure(let error):
                throw error
            }
        }
        semaphore = DispatchSemaphore(value: 0)
        semaphore?.wait()
        if let result = savedResult {
            switch result {
            case .success(let output):
                return output
            case .failure(let error):
                throw error
            }
        }
        throw RequestError.unknown
    }

    fileprivate func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        if let error = error {
            // Avoid wrapping RequestError
            if let requestError = error as? RequestError {
                callFailureHandler(requestError)
                return true
            }
            callFailureHandler(.urlSessionError(error: error))
            return true
        }
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            callFailureHandler(.noResponse)
            return true
        }
        guard statusCode < 400 else {
            callFailureHandler(.httpError(statusCode: statusCode, errorString: HTTPURLResponse.localizedString(forStatusCode: statusCode), responseBody: data ?? Data()))
            return true
        }
        return false
    }

    fileprivate func callFailureHandler(_ requestError: RequestError) {
        failureHandler?(requestError)
        savedResult = .failure(requestError)
        semaphore?.signal()
    }

    fileprivate func callSuccessHandler(_ output: Output) {
        successHandler?(output)
        savedResult = .success(output)
        semaphore?.signal()
    }

    public class func get(url: String,
                          parameters: [String: String] = [:],
                          headers: [String: String]? = nil,
                          success: (@Sendable (Output) -> Void)? = nil,
                          failure: (@Sendable (RequestError) -> Void)? = nil,
                          session: URLSession = .shared) -> Self {
        nonisolated(unsafe) let handler = self.init(success: success, failure: failure)
        let task = session.get(from: url, parameters: parameters, headers: headers) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }

    public class func post(url: String,
                           parameters: [String: String] = [:],
                           headers: [String: String]? = nil,
                           success: (@Sendable (Output) -> Void)? = nil,
                           failure: (@Sendable (RequestError) -> Void)? = nil,
                           session: URLSession = .shared) -> Self {
        nonisolated(unsafe) let handler = self.init(success: success, failure: failure)
        let task = session.post(to: url, parameters: parameters, headers: headers) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }

    public class func post<T: Encodable>(url: String,
                                         json: T,
                                         encoder: JSONEncoder? = nil,
                                         headers: [String: String]? = nil,
                                         success: (@Sendable (Output) -> Void)? = nil,
                                         failure: (@Sendable (RequestError) -> Void)? = nil,
                                         session: URLSession = .shared) -> Self {
        nonisolated(unsafe) let handler = self.init(success: success, failure: failure)
        let task = session.post(to: url, json: json, encoder: encoder, headers: headers) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }

    public class func upload(url: String,
                             data: Data, key: String = "file", filename: String,
                             parameters: [String: String] = [:],
                             headers: [String: String]? = nil,
                             success: (@Sendable (Output) -> Void)? = nil,
                             failure: (@Sendable (RequestError) -> Void)? = nil,
                             session: URLSession = .shared) -> Self {
        nonisolated(unsafe) let handler = self.init(success: success, failure: failure)
        let task = session.upload(to: url, parameters: parameters, data: data, key: key, filename: filename, headers: headers) { (data, response, error) in
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
        callSuccessHandler(())
        return false
    }
}

public class DataRequestHandler: BaseRequestHandler<Data> {
    override func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard !super.commonHandler(data: data, response: response, error: error) else {
            return true
        }
        callSuccessHandler(data ?? Data())
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
            let output = try (Output.decoder ?? JSONDecoder()).decode(Output.self, from: data ?? Data())
            callSuccessHandler(output)
            return false
        } catch let error {
            callFailureHandler(.decodingError(error: error))
            return true
        }
    }
}
