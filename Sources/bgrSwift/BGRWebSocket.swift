//
//  BGRWebSocket.swift
//  bgrSwift
//
//  Created by Mehmet Buğra BALCI on 2.04.2025.
//

import Foundation

public struct BGRWebSocketModel {
    public let urlString: String
    public let handshakeMessage: [String: Any]
    public let headers: [(String?, String)]?
    
    public init(
        urlString: String,
        handshakeMessage: [String : Any],
        headers: [(String?, String)]?
    ) {
        self.urlString = urlString
        self.handshakeMessage = handshakeMessage
        self.headers = headers
    }
    
    var uRLRequest: URLRequest? {
        guard let url = URL(string: self.urlString) else { return nil }
        
        var urlRequest = URLRequest(url: url)
        
        if let headers, !headers.isEmpty {
            headers.forEach { (key, value) in
                urlRequest.setValue(key, forHTTPHeaderField: value)
            }
        }
        
        return urlRequest
    }
}

public struct BGRWebSocket {
    private var webSocketTask: URLSessionWebSocketTask? = nil
    private var model: BGRWebSocketModel? = nil
    
    public var onMessageReceived: ((String) -> Void)?
    
    public init(model: BGRWebSocketModel) {
        guard let urlRequest = model.uRLRequest else { return }
        
        self.model = model
        
        let session = URLSession(configuration: .default)
        
        webSocketTask = session.webSocketTask(with: urlRequest)
    }
    
    public func connect(completion: @escaping (Bool) -> Void) {
        webSocketTask?.resume()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            if let handshakeMessage = model?.handshakeMessage,
               let handshakeJson = self.getJsonString(for: handshakeMessage) {
                
                self.send(handshakeJson)
                
                if webSocketTask?.state == .running {
                    print("✅ Websocket Connected!")
                    self.receiveMessages()
                    completion(true)
                }
            }
            completion(false)
        }
    }
    
    public func close() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        print("🔴 WebSocket shut down!")
    }
    
    public func send(_ jsonString: String) {
        guard let webSocketTask = self.webSocketTask else { return }
        
        let formattedMessage = jsonString + "\u{001E}"
        let message = URLSessionWebSocketTask.Message.string(formattedMessage)
        
        webSocketTask.send(message) { error in
            if let error = error {
                print("❗️Message sending error!: \(error.localizedDescription)")
            } else {
                print("📨 Message sended!: \(message)")
            }
        }
    }
    
    private func receiveMessages() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📩 Gelen mesaj: \(text)")
                    self.onMessageReceived?(text)
                default:
                    print("⚠️ Beklenmeyen mesaj türü")
                }
                
                // Yeni mesajları dinlemeye devam et
                self.receiveMessages()
                
            case .failure(let error):
                print("❌ WebSocket mesaj alma hatası: \(error.localizedDescription)")
                if webSocketTask.state != .running {
                    print("🚨 WebSocket bağlantısı kapandı!")
                }
            }
        }
    }
    
    public func getJsonString(for dictionary: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
        
        return jsonString
    }
    
    public func getJsonString<T: Codable>(for model: T) -> String? {
        guard let jsonData = try? JSONEncoder().encode(model),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
        
        return jsonString
    }
}
