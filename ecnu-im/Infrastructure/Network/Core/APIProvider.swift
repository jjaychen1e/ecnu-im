//
//  APIProvider.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Alamofire
import Combine
import Foundation

/// Closure to be executed when a request has completed.
public typealias Completion = (_ result: Result<Response, NetworkError>) -> Void

class APIProvider<Target: TargetType> {
    let session: Session

    init() {
        session = Self.defaultAlamofireSession()
    }

    func request(_ target: Target,
                 completion: @escaping Completion) {
        return requestInternal(target, completion: completion)
    }

    func request(_ target: Target) async throws -> Response {
        return try await requestInternal(target)
    }
}

extension APIProvider {
    private func requestInternal(_ target: Target, completion: @escaping Completion) {
        Task {
            let endpoint = await Self.defaultEndpointMapping(for: target)
            do {
                let request = try endpoint.urlRequest()
                session.request(request).response { response in
                    let result = convertResponseToResult(response.response, request: request, data: response.data, error: response.error)
                    completion(result)
                }.resume()
            } catch _ {}
        }
    }

    private func requestInternal(_ target: Target) async throws -> Response {
        let endpoint = await Self.defaultEndpointMapping(for: target)
        let request = try endpoint.urlRequest()

        let dataTask = session.request(request).serializingData()
        dataTask.resume()
        let response = await dataTask.response

        let result = convertResponseToResult(response.response, request: request, data: response.data, error: response.error)
        return try result.get()
    }
}

extension APIProvider {
    class func defaultEndpointMapping(for target: Target) async -> Endpoint {
        Endpoint(
            url: URL(target: target).absoluteString,
            method: target.method,
            task: target.task,
            httpHeaderFields: await target.headers
        )
    }

    class func defaultAlamofireSession() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default

        return Session(configuration: configuration, startRequestsImmediately: false)
    }
}

/// A public function responsible for converting the result of a `URLRequest` to a Result<Response, NetworkError>.
public func convertResponseToResult(_ response: HTTPURLResponse?, request: URLRequest?, data: Data?, error: Swift.Error?) ->
    Result<Response, NetworkError> {
    switch (response, data, error) {
    case let (.some(response), data, .none):
        let response = Response(statusCode: response.statusCode, data: data ?? Data(), request: request, response: response)
        return .success(response)
    case let (.some(response), _, .some(error)):
        let response = Response(statusCode: response.statusCode, data: data ?? Data(), request: request, response: response)
        let error = NetworkError.underlying(error, response)
        return .failure(error)
    case let (_, _, .some(error)):
        let error = NetworkError.underlying(error, nil)
        return .failure(error)
    default:
        let error = NetworkError.underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil), nil)
        return .failure(error)
    }
}
