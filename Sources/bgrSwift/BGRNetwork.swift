//
//  BGRNetwork.swift
//
//
//  Created by Mehmet Buğra BALCI on 21.01.2025.
//

import Foundation

public enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
}

public enum BGRNetworkError: Error {
    case requestError
    case responseError
    case decodingError
}

protocol BGRNetwork {
    var decoder: JSONDecoder { get set }
    func request<T: Codable>(model: RequestModel<T>) async throws -> T
}

public struct NetworkNew: BGRNetwork {
    public init() { }
    
    var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    @discardableResult public func request<T: Codable>(model: RequestModel<T>) async throws -> T {
        guard let uRLRequest = model.uRLRequest else { throw BGRNetworkError.requestError }
        
        let (data, response) = try await URLSession.shared.data(for: uRLRequest)
        
        getRequestInfo(data: data, response: response as? HTTPURLResponse)
        
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else { throw BGRNetworkError.responseError }
        
        do {
            let decodedData = try decoder.decode(model.responseModel.self, from: data)
            return decodedData
        } catch {
            throw BGRNetworkError.decodingError
        }
    }
    
    private func getRequestInfo(data: Data, response: HTTPURLResponse?) -> String {
        var requestInfo = "*** REQUEST INFO ***"
        requestInfo.append("\n********************")
        
        if let response = response {
            requestInfo.append("\n* Status Code: \(response.statusCode)")
            requestInfo.append("\n* URL: \(response.url?.absoluteString ?? "-")")
            requestInfo.append("\n* Mime Type: \(response.mimeType ?? "-")")
        }

        requestInfo.append("\n* Response Data ↓")
        requestInfo.append("\n________________⌋")
        requestInfo.append("\n \(String(data: data, encoding: .utf8) ?? "-")")
        requestInfo.append("\n------------------")
        
        return requestInfo
    }
}
