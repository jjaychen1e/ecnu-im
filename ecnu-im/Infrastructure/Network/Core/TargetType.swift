//
//  TargetType.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Alamofire
import Foundation

typealias HTTPMethod = Alamofire.HTTPMethod
typealias Session = Alamofire.Session
typealias Request = Alamofire.Request
typealias DownloadRequest = Alamofire.DownloadRequest
typealias UploadRequest = Alamofire.UploadRequest
typealias DataRequest = Alamofire.DataRequest

typealias URLRequestConvertible = Alamofire.URLRequestConvertible

/// Choice of parameter encoding.
typealias ParameterEncoding = Alamofire.ParameterEncoding
typealias JSONEncoding = Alamofire.JSONEncoding
typealias URLEncoding = Alamofire.URLEncoding

/// Multipart form.
typealias RequestMultipartFormData = Alamofire.MultipartFormData

/// Multipart form data encoding result.
typealias DownloadDestination = Alamofire.DownloadRequest.Destination

/// The protocol used to define the specifications necessary for a `APIProvider`.
protocol TargetType {
    /// The target's base `URL`.
    var baseURL: URL { get }

    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }

    /// The HTTP method used in the request.
    var method: HTTPMethod { get }

    /// The type of HTTP task to be performed.
    var task: RequestTask { get }

    /// The headers to be used in the request.
    var headers: [String: String]? { get }
}
