//
//  File.swift
//  
//
//  Created by Mehmet Buğra BALCI on 23.12.2024.
//

import Foundation

open class Network {
    private let decoder = JSONDecoder()
    
    public enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    
    public enum NetworkError: Error {
        case requestError
        case responseError
        case undefined
    }
    
    public struct Model<T: Codable> {
        public let urlString: String?
        public let responseModel: T.Type
        public let method: Method?
        public let parameters: [String: Any]?
        
        public init(urlString: String?, responseModel: T.Type, method: Method? = .get, parameters: [String: Any]? = nil) {
            self.urlString = urlString
            self.responseModel = responseModel
            self.method = method
            self.parameters = parameters
        }
        
        var uRLComponents: URLComponents? {
            guard let url = self.urlString else { return nil }
            
            var urlComp = URLComponents(string: url)
            
            if let parameters = self.parameters, !parameters.isEmpty,
               self.method == .get {
                
                var queryItemArr: [URLQueryItem] = []
                
                parameters.forEach { (key, value) in
                    queryItemArr.append(URLQueryItem(name: key, value: String(describing: value)))
                }
                
                urlComp?.queryItems = queryItemArr
            }
            
            return urlComp
        }
        
        var uRLRequest: URLRequest? {
            guard let url = uRLComponents?.url else { return nil }
            var urlRequest = URLRequest(url: url)
            
            urlRequest.httpMethod = method?.rawValue
            
            if let parameters = parameters, !(parameters.isEmpty),
               method == .post {
                urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            }
            
            return urlRequest
        }
    }
    
    public init() {}
    
    @available(iOS 15.0, *)
    public func request<T: Codable>(requestModel: Model<T>) async throws -> Result<T, Error> {
        guard let urlRequest = requestModel.uRLRequest else { return .failure(NetworkError.requestError) }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else { return .failure(NetworkError.responseError) }
        
        print(getRequestInfo(data: data, response: httpResponse))
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
            let decodedData = try decoder.decode(T.self, from: data)
            
            return .success(decodedData)
        } else {
            return .failure(NetworkError.responseError)
        }
    }
    
    private func getRequestInfo(data: Data, response: HTTPURLResponse) -> String {
        var requestInfo = "*** REQUEST INFO ***"
        requestInfo.append("\n********************")
        requestInfo.append("\n* Status Code: \(response.statusCode)")
        requestInfo.append("\n* URL: \(response.url?.absoluteString ?? "-")")
        requestInfo.append("\n* Mime Type: \(response.mimeType ?? "-")")
        
        requestInfo.append("\n* Response Data ↓")
        requestInfo.append("\n________________⌋")
        requestInfo.append("\n \(String(data: data, encoding: .utf8) ?? "-")")
        requestInfo.append("\n------------------")
        
        return requestInfo
    }
}
