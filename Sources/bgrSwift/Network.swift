//
//  File.swift
//  
//
//  Created by Mehmet Buğra BALCI on 23.12.2024.
//

import Foundation

open class Network {
    private let decoder = JSONDecoder()
    
    public init() {}
    
    public enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    
    public struct Model<T: Codable> {
        public let url: URL?
        public let responseModel: T.Type
        public let method: Method?
        public let parameters: [String: Any]?
        
        public init(url: URL?, responseModel: T.Type, method: Method? = .get, parameters: [String: Any]? = nil) {
            self.url = url
            self.responseModel = responseModel
            self.method = method
            self.parameters = parameters
        }
    }
    
    public enum NetworkError: Error {
        case urlError
        case responseError
        case undefined
    }
    
    @available(iOS 15.0, *)
    public func request<T: Codable>(requestModel: Model<T>) async throws -> Result<T, Error> {
        guard let url = requestModel.url else { return .failure(NetworkError.urlError)}
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = requestModel.method?.rawValue
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else { return .failure(NetworkError.responseError) }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
            let decodedData = try decoder.decode(T.self, from: data)
            return .success(decodedData)
        } else {
            return .failure(NetworkError.responseError)
        }
    }
}
