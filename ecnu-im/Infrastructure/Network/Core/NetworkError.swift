//
//  NetworkError.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

public enum NetworkError: Error {
    /// Indicates a response failed to map to an image.
    case imageMapping(Response)

    /// Indicates a response failed to map to a JSON structure.
    case jsonMapping(Response)

    /// Indicates a response failed to map to a String.
    case stringMapping(Response)

    /// Indicates a response failed to map to a Decodable object.
    case objectMapping(Error, Response)

    /// Indicates that Encodable couldn't be encoded into Data
    case encodableMapping(Error)

    /// Indicates a response failed with an invalid HTTP status code.
    case statusCode(Response)

    /// Indicates a response failed due to an underlying `Error`.
    case underlying(Error, Response?)

    /// Indicates that an `Endpoint` failed to map to a `URLRequest`.
    case requestMapping(String)

    /// Indicates that an `Endpoint` failed to encode the parameters for the `URLRequest`.
    case parameterEncoding(Error)
}
