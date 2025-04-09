//
//  BGRWebSocket.swift
//  bgrSwift
//
//  Created by Mehmet Buğra BALCI on 2.04.2025.
//

import Foundation

public class BGRWebSocket {
    var webSocketTask: URLSessionWebSocketTask? = nil
    
    public init() { }
    
    public func connect<T: Codable>(model: RequestModel<T>) {
        guard let uRLRequest = model.uRLRequest else {
            print("Something went wrong! Please check your URL.")
            return
        }
        
        self.webSocketTask = URLSession.shared.webSocketTask(with: uRLRequest)
        self.webSocketTask?.resume()
    }
}
