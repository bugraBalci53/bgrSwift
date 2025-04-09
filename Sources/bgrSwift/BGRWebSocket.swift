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
               let handshakeJson = self.getJsonString(for: handshakeMessage){
                
                self.send(handshakeJson)
                
                if webSocketTask?.state == .running {
                    print("Websocket Connected!")
                    self.receiveMessages()
                    completion(true)
                }
            }
            completion(false)
        }
    }
    
    public func send(_ jsonString: String) {
        guard let webSocketTask = self.webSocketTask else { return }
        
        let formattedMessage = jsonString + "\u{001E}"  // SignalR için gerekli olabilir
        let message = URLSessionWebSocketTask.Message.string(formattedMessage)
        
        webSocketTask.send(message) { error in
            if let error = error {
                print("❌ Message sending error!: \(error.localizedDescription)")
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

//public class SignalRWebSocket {
//    private var webSocketTask: URLSessionWebSocketTask?
//    private let urlString = "ws://localhost:5168/chatHub"
//    
//    public init() { }
//    
//    public func connect() {
//        guard let url = URL(string: urlString) else {
//            print("❌ Geçersiz URL")
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("SignalR", forHTTPHeaderField: "Sec-WebSocket-Protocol") // Eğer sunucu istiyorsa
//        
//        let session = URLSession(configuration: .default)
//        webSocketTask = session.webSocketTask(with: request)
//        webSocketTask?.resume()
//        
//        print("🔌 WebSocket bağlantısı başlatıldı...")
//        
//        // 1 saniye bekleyip handshake mesajı gönder
//        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
//            self.sendHandshake()
//            self.receiveMessages()
//        }
//        
//        // Mesajları dinlemeye başla
//    }
//    
//    private func sendHandshake() {
//        let handshakeMessage: [String: Any] = ["protocol": "json", "version": 1]
//        guard let jsonData = try? JSONSerialization.data(withJSONObject: handshakeMessage),
//              let jsonString = String(data: jsonData, encoding: .utf8) else {
//            print("❌ JSON formatına çevirme hatası")
//            return
//        }
//        
//        sendMessage(jsonString)
//    }
//    
//    public func sendMessage(_ message: String) {
//        guard let webSocketTask = webSocketTask else {
//            print("❌ WebSocket bağlantısı yok")
//            return
//        }
//        
//        let formattedMessage = message + "\u{001E}"  // SignalR için gerekli olabilir
//        let wsMessage = URLSessionWebSocketTask.Message.string(formattedMessage)
//        
//        webSocketTask.send(wsMessage) { error in
//            if let error = error {
//                print("❌ Mesaj gönderme hatası: \(error.localizedDescription)")
//            } else {
//                print("📨 Mesaj gönderildi: \(formattedMessage)")
//            }
//        }
//    }
//    
//    private func receiveMessages() {
//        guard let webSocketTask = webSocketTask else { return }
//        
//        webSocketTask.receive { [weak self] result in
//            switch result {
//            case .success(let message):
//                switch message {
//                case .string(let text):
//                    print("📩 Gelen mesaj: \(text)")
//                default:
//                    print("⚠️ Beklenmeyen mesaj türü")
//                }
//                
//                // Yeni mesajları dinlemeye devam et
//                self?.receiveMessages()
//                
//            case .failure(let error):
//                print("❌ WebSocket mesaj alma hatası: \(error.localizedDescription)")
//                if webSocketTask.state != .running {
//                    print("🚨 WebSocket bağlantısı kapandı!")
//                }
//            }
//        }
//    }
//    
//    func close() {
//        webSocketTask?.cancel(with: .goingAway, reason: nil)
//        print("🔌 WebSocket bağlantısı kapatıldı.")
//    }
//}
