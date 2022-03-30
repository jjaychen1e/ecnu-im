//
//  Endpoint.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

class Endpoint {
    /// A string representation of the URL for the request.
    public let url: String

    /// The HTTP method for the request.
    public let method: HTTPMethod

    /// The `Task` for the request.
    public let task: RequestTask

    /// The HTTP header fields for the request.
    public let httpHeaderFields: [String: String]?

    public init(url: String,
                method: HTTPMethod,
                task: RequestTask,
                httpHeaderFields: [String: String]?)
    {
        self.url = url
        self.method = method
        self.task = task
        self.httpHeaderFields = httpHeaderFields
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with added HTTP header fields.
    func adding(newHTTPHeaderFields: [String: String]) -> Endpoint {
        Endpoint(url: url, method: method, task: task, httpHeaderFields: add(httpHeaderFields: newHTTPHeaderFields))
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with replaced `task` parameter.
    func replacing(task: RequestTask) -> Endpoint {
        Endpoint(url: url, method: method, task: task, httpHeaderFields: httpHeaderFields)
    }

    fileprivate func add(httpHeaderFields headers: [String: String]?) -> [String: String]? {
        guard let unwrappedHeaders = headers, unwrappedHeaders.isEmpty == false else {
            return httpHeaderFields
        }

        var newHTTPHeaderFields = httpHeaderFields ?? [:]
        unwrappedHeaders.forEach { key, value in
            newHTTPHeaderFields[key] = value
        }
        return newHTTPHeaderFields
    }
}

/// Extension for converting an `Endpoint` into a `URLRequest`.
extension Endpoint {
    // swiftlint:disable cyclomatic_complexity
    /// Returns the `Endpoint` converted to a `URLRequest` if valid. Throws an error otherwise.
    func urlRequest() throws -> URLRequest {
        guard let requestURL = Foundation.URL(string: url) else {
            throw NetworkError.requestMapping(url)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        switch task {
        case .requestPlain, .uploadFile, .uploadMultipart, .downloadDestination:
            return request
        case let .requestData(data):
            request.httpBody = data
            return request
        case let .requestJSONEncodable(encodable):
            return try request.encoded(encodable: encodable)
        case let .requestCustomJSONEncodable(encodable, encoder: encoder):
            return try request.encoded(encodable: encodable, encoder: encoder)
        case let .requestParameters(parameters, parameterEncoding):
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .uploadCompositeMultipart(_, urlParameters):
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .downloadParameters(parameters, parameterEncoding, _):
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .requestCompositeData(bodyData: bodyData, urlParameters: urlParameters):
            request.httpBody = bodyData
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .requestCompositeParameters(bodyParameters: bodyParameters, bodyEncoding: bodyParameterEncoding, urlParameters: urlParameters):
            if let bodyParameterEncoding = bodyParameterEncoding as? URLEncoding, bodyParameterEncoding.destination != .httpBody {
                fatalError("Only URLEncoding that `bodyEncoding` accepts is URLEncoding.httpBody. Others like `default`, `queryString` or `methodDependent` are prohibited - if you want to use them, add your parameters to `urlParameters` instead.")
            }
            let bodyfulRequest = try request.encoded(parameters: bodyParameters, parameterEncoding: bodyParameterEncoding)
            let urlEncoding = URLEncoding(destination: .queryString)
            return try bodyfulRequest.encoded(parameters: urlParameters, parameterEncoding: urlEncoding)
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
