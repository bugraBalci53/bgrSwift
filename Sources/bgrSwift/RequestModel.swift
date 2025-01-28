//
//  File.swift
//  
//
//  Created by Mehmet Buğra BALCI on 24.01.2025.
//

import Foundation

public struct RequestModel<T: Codable> {
    public let urlString: String
    public let method: RequestMethod
    public let parameters: [String: Any]?
    public let responseModel: (T.Type)
    
    public init(urlString: String, method: RequestMethod, parameters: [String : Any]?, responseModel: T.Type) {
        self.urlString = urlString
        self.method = method
        self.parameters = parameters
        self.responseModel = responseModel
    }
    
    var uRLComponents: URLComponents? {
        var urlComp = URLComponents(string: urlString)
        
        if let parameters, !parameters.isEmpty, self.method == .get {
            urlComp?.queryItems = parameters.map({ URLQueryItem(name: $0.key, value: String(describing: $0.value)) })
        }
        
        return urlComp
    }
    
    var uRLRequest: URLRequest? {
        guard let url = uRLComponents?.url else { return nil }
        
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = method.rawValue
        
        if let parameters, !parameters.isEmpty, method == .post {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        return urlRequest
    }
}
