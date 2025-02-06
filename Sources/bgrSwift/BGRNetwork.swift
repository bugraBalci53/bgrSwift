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
    case requestError(errorMessage: String)
    case responseError(errorMessage: String)
    case decodingError(errorMessage: String)
    
    var errorMessage: String {
        switch self {
        case .requestError(let errorMessage), .responseError(let errorMessage), .decodingError(let errorMessage):
            return errorMessage
        }
    }
}

protocol BGRNetwork {
    var decoder: JSONDecoder { get }
    func request<T: Codable>(model: RequestModel<T>) async throws -> T
}

public struct NetworkNew: BGRNetwork {
    public init() { }
    
    var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    @discardableResult public func request<T: Codable>(model: RequestModel<T>) async throws -> T {
        guard let uRLRequest = model.uRLRequest else { throw BGRNetworkError.requestError(errorMessage: "Something went wrong! Please check your URL.") }
        
        let (data, response) = try await URLSession.shared.data(for: uRLRequest)
        
        print(getRequestInfo(data: data, response: response as? HTTPURLResponse))
        
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else { throw BGRNetworkError.responseError(errorMessage: "Something went wrong! Check your status code.")
        }
        
        do {
            let decodedData = try decoder.decode(model.responseModel.self, from: data)
            return decodedData
        } catch {
            throw BGRNetworkError.decodingError(errorMessage: "Something went wrong! Please check your response model.")
        }
    }
    
    public func request<T: Codable>(model: RequestModel<T>, completion: @escaping (Result<T, BGRNetworkError>) -> Void) async {
        guard let uRLRequest = model.uRLRequest else {
            completion(.failure(.requestError(errorMessage: "Something went wrong! Please check your URL.")))
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: uRLRequest)
            
            getRequestInfo(data: data, response: response as? HTTPURLResponse)
            
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                completion(.failure(.responseError(errorMessage: "Something went wrong! Please check the response.")))
                return
            }
            
            do {
                let decodedData = try decoder.decode(model.responseModel.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(.decodingError(errorMessage: "Something went wrong! Please compare your response model with the response.")))
            }
        } catch {
            completion(.failure(.requestError(errorMessage: "Something went wrong! Please check your connection.")))
        }
    }
}

extension NetworkNew {
    @discardableResult private func getRequestInfo(data: Data, response: HTTPURLResponse?) -> String {
        var requestInfo = "*** REQUEST INFO ***"
        requestInfo.append("\n********************")
        
        if let response = response {
            requestInfo.append("\n* Status Code: \(response.statusCode)")
            requestInfo.append("\n* URL: \(response.url?.absoluteString ?? "-")")
            requestInfo.append("\n* Mime Type: \(response.mimeType ?? "-")")
        }

        requestInfo.append("\n* Response Data ↓")
        requestInfo.append("\n________________⌋")
        requestInfo.append("\n \(String(data: data, encoding: .utf8) ?? "There is no data!")")
        requestInfo.append("\n------------------")
        
        print(requestInfo)
        
        return requestInfo
    }
}
