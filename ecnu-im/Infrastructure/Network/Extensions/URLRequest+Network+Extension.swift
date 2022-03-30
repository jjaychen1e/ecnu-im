//
//  URLRequest+Network+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

internal extension URLRequest {
    mutating func encoded(encodable: Encodable, encoder: JSONEncoder = JSONEncoder()) throws -> URLRequest {
        do {
            let encodable = AnyEncodable(encodable)
            httpBody = try encoder.encode(encodable)

            let contentTypeHeaderName = "Content-Type"
            if value(forHTTPHeaderField: contentTypeHeaderName) == nil {
                setValue("application/json", forHTTPHeaderField: contentTypeHeaderName)
            }

            return self
        } catch {
            throw NetworkError.encodableMapping(error)
        }
    }

    func encoded(parameters: [String: Any], parameterEncoding: ParameterEncoding) throws -> URLRequest {
        do {
            return try parameterEncoding.encode(self, with: parameters)
        } catch {
            throw NetworkError.parameterEncoding(error)
        }
    }
}
