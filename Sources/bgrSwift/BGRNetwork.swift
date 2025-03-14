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
    
    public var errorMessage: String {
        switch self {
        case .requestError(let errorMessage), .responseError(let errorMessage), .decodingError(let errorMessage):
            return errorMessage
        }
    }
}

protocol BGRNetwork {
    var decoder: JSONDecoder { get }
    func request<T: Decodable>(model: RequestModel<T>, completion: @escaping (Result<T, BGRNetworkError>) -> Void) async
}

public struct Network: BGRNetwork {
    public init() { }
    
    var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    public func request<T: Decodable>(model: RequestModel<T>, completion: @escaping (Result<T, BGRNetworkError>) -> Void) async {
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

extension BGRNetwork {
    /// it prints the request info to console
    /// - Parameters:
    ///   - data: data from the request
    ///   - response: response from the request
    func getRequestInfo(data: Data, response: HTTPURLResponse?) {
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
    }
}

extension Result {
    /// if the result is .success then it returns data; otherwise, it returns nil
    public var successData: Success? {
        guard case .success(let success) = self else { return nil }

        return success
    }
}
