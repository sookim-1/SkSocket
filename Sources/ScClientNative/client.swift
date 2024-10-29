//
//  client.swift
//  ScClientNative
//
//  Created by sookim on 10/28/24.
//

import Foundation

public class ScClient: Listener {

    var authToken: String?
    var url: URL
    var protocols: [String]
    var socket: URLSessionWebSocketTask
    var counter: AtomicInteger

    var onConnect: ((ScClient)-> Void)?
    var onConnectError: ((ScClient, Error?)-> Void)?
    var onDisconnect: ((ScClient, Error?)-> Void)?
    var onSetAuthentication: ((ScClient, String?)-> Void)?
    var onAuthentication: ((ScClient, Bool?)-> Void)?

    public init(url: String, authToken: String? = nil, protocols: [String] = []) {
        self.counter = AtomicInteger()
        self.authToken = authToken
        self.url = URL(string: url)!
        self.protocols = protocols
        self.socket = URLSession.shared.webSocketTask(with: self.url, protocols: self.protocols)
        super.init()
        socket.delegate = self
    }

    public func connect() {
        self.socket.resume()
    }

    public func reconnect() {
        self.socket = URLSession.shared.webSocketTask(with: self.url, protocols: protocols)
        self.socket.delegate = self
        self.socket.resume()
    }

    public func isConnected() -> Bool {
        self.socket.state == .running
    }

    public func disconnect() {
        self.socket.cancel()
    }

    public func setAuthToken(token: String) {
        self.authToken = token
    }

    public func getAuthToken() -> String? {
        return self.authToken
    }

    public func setBasicListener(onConnect: ((ScClient)-> Void)?, onConnectError: ((ScClient, Error?)-> Void)?, onDisconnect: ((ScClient, Error?)-> Void)?) {
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onConnectError = onConnectError
    }

    public func setAuthenticationListener (onSetAuthentication: ((ScClient, String?)-> Void)?, onAuthentication: ((ScClient, Bool?)-> Void)?) {
        self.onSetAuthentication = onSetAuthentication
        self.onAuthentication = onAuthentication
    }

}

// MARK: - Event
extension ScClient {

    private func sendHandShake(completionHandler: @escaping (Error?) -> Void) {
        let handshake = Model.getHandshakeObject(authToken: self.authToken, messageId: counter.incrementAndGet())

        self.socket.send(.string(handshake.toJSONString()!), completionHandler: completionHandler)
    }

    private func ack(cid: Int, completionHandler: @escaping (Error?) -> Void) -> (AnyObject?, AnyObject?) -> Void {
        return  {
            (error: AnyObject?, data: AnyObject?) in
            let ackObject = Model.getReceiveEventObject(data: JSONConverter.jsonString(from: data), error: JSONConverter.jsonString(from: error), messageId: cid)
            self.socket.send(.string(ackObject.toJSONString()!), completionHandler: completionHandler)
        }
    }

    public func emit<T: Encodable>(eventName: String, data: T?, completionHandler: @escaping (Error?) -> Void) {
        let emitObject = Model.getEmitEventObject(eventName: eventName, data: data, messageId: counter.incrementAndGet())
        self.socket.send(.string(emitObject.toJSONString()!), completionHandler: completionHandler)
    }

    public func emitAck<T: Encodable>(eventName: String, data: T?, ack: @escaping AckHandler, completionHandler: @escaping (Error?) -> Void) {
        let id = counter.incrementAndGet()
        let emitObject = Model.getEmitEventObject(eventName: eventName, data: data, messageId: id)
        putEmitAck(id: id, eventName: eventName, ack: ack)
        self.socket.send(.string(emitObject.toJSONString()!), completionHandler: completionHandler)
    }

    public func subscribe(channelName: String, token: String? = nil, completionHandler: @escaping (Error?) -> Void) {
        let subscribeObject = Model.getSubscribeEventObject(channelName: channelName, messageId: counter.incrementAndGet(), token : token)
        self.socket.send(.string(subscribeObject.toJSONString()!), completionHandler: completionHandler)
    }

    public func subscribeAck(channelName: String, token: String? = nil, ack: @escaping AckHandler, completionHandler: @escaping (Error?) -> Void) {
        let id = counter.incrementAndGet()
        let subscribeObject = Model.getSubscribeEventObject(channelName: channelName, messageId: id, token: token)
        putEmitAck(id: id, eventName: channelName, ack: ack)
        self.socket.send(.string(subscribeObject.toJSONString()!), completionHandler: completionHandler)
    }

    public func unsubscribe(channelName: String, completionHandler: @escaping (Error?) -> Void) {
        let unsubscribeObject = Model.getUnsubscribeEventObject(channelName: channelName, messageId: counter.incrementAndGet())
        self.socket.send(.string(unsubscribeObject.toJSONString()!), completionHandler: completionHandler)
    }

    public func unsubscribeAck(channelName: String, ack: @escaping AckHandler, completionHandler: @escaping (Error?) -> Void) {
        let id = counter.incrementAndGet()
        let unsubscribeObject = Model.getUnsubscribeEventObject(channelName: channelName, messageId: id)
        putEmitAck(id: id, eventName: channelName, ack: ack)
        self.socket.send(.string(unsubscribeObject.toJSONString()!), completionHandler: completionHandler)
    }

    public func publish<T: Encodable>(channelName: String, data: T?, completionHandler: @escaping (Error?) -> Void) {
        let publishObject = Model.getPublishEventObject(channelName: channelName, data: data, messageId: counter.incrementAndGet())
        self.socket.send(.string(publishObject.toJSONString()!), completionHandler: completionHandler)
    }

    public func publishAck<T: Encodable>(channelName: String, data: T?, ack: @escaping AckHandler, completionHandler: @escaping (Error?) -> Void) {
        let id = counter.incrementAndGet()
        let publishObject = Model.getPublishEventObject(channelName: channelName, data: data, messageId: id)
        putEmitAck(id: id, eventName: channelName, ack: ack)
        self.socket.send(.string(publishObject.toJSONString()!), completionHandler: completionHandler)
    }

    public func onChannel(channelName: String, ack: @escaping (String, AnyObject?) -> Void) {
        putOnListener(eventName: channelName, onListener: ack)
    }

    public func on(eventName: String, ack: @escaping (String, AnyObject?) -> Void) {
        putOnListener(eventName: eventName, onListener: ack)
    }

    public func onAck(eventName: String, ack: @escaping (String, AnyObject?, (AnyObject?, AnyObject?) -> Void) -> Void) {
        putOnAckListener(eventName: eventName, onAckListener: ack)
    }

    public func sendPing(completionHandler: @escaping (Error?) -> Void) {
        self.socket.sendPing(pongReceiveHandler: completionHandler)
    }

    public func sendEmptyDataEvent(completionHandler: @escaping (Error?) -> Void) {
        self.socket.send(.data(Data()), completionHandler: completionHandler)
    }

    public func sendEmptyStringEvent(completionHandler: @escaping (Error?) -> Void) {
        self.socket.send(.string(""), completionHandler: completionHandler)
    }

    public func startWebsocketDidReceive() {
        guard isConnected() else { return }

        self.socket.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let success):
                switch success {
                case .data(let data):
                    self.websocketDidReceiveData(data: data)
                case .string(let string):
                    guard let messageData = string.data(using: .utf8) else { return }

                    let str = String(decoding: messageData, as: UTF8.self)
                    print("💬 Received message: \(str)")

                    self.websocketDidReceiveMessage(text: string)
                default:
                    print("DidReceive Error")
                }
            case .failure(let failure):
                print("DidReceive Error: \(failure)")
            }

            self.startWebsocketDidReceive()
        }
    }

    public func websocketDidReceiveMessage(text: String) {
        if let messageObject = JSONConverter.deserializeString(message: text),
           let (data, rid, cid, eventName, error) = Parser.getMessageDetails(myMessage: messageObject) {

            let parseResult = Parser.parse(rid: rid, cid: cid, event: eventName)

            switch parseResult {
            case .isAuthenticated:
                let isAuthenticated = ClientUtils.getIsAuthenticated(message: messageObject)
                onAuthentication?(self, isAuthenticated)
            case .publish:
                guard let dictionary = data as? [String: Any],
                      let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
                      let jsonString =  String(data: jsonData, encoding: .utf8)
                else { return }

                if let channel = Model.getChannelObject(data: jsonString) {
                    handleOnListener(eventName: channel.channel, data: channel.data as AnyObject)
                }

                /* FIXME: [String: Any], AnyObject 처리
                if let channel = Model.getChannelObject(data: JSONConverter.jsonString(from: data)) {
                    handleOnListener(eventName: channel.channel, data: channel.data as AnyObject)
                }
                */
            case .removeToken:
                self.authToken = nil
            case .setToken:
                authToken = ClientUtils.getAuthToken(message: messageObject)
                self.onSetAuthentication?(self, authToken)
            case .ackReceive:
                handleEmitAck(id: rid!, error: error as AnyObject, data: data as AnyObject)
            case .event:
                if hasEventAck(eventName: eventName!) {
                    handleOnAckListener(eventName: eventName!, data: data as AnyObject, ack: self.ack(cid: cid!, completionHandler: { _ in }))
                } else {
                    handleOnListener(eventName: eventName!, data: data as AnyObject)
                }
            }
        }
    }

    public func websocketDidReceiveData(data: Data) {
        print("Received data: \(data.count)")
    }

}

// MARK: - URLSessionWebSocketDelegate
extension ScClient: URLSessionWebSocketDelegate {

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        counter.value = 0

        self.sendHandShake { [weak self] error in
            guard let self else { return }

            DispatchQueue.global().async {
                self.startWebsocketDidReceive()
            }

            DispatchQueue.main.async {
                self.onConnect?(self)
            }
        }
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.onDisconnect?(self, WebSocketError.findMatchError(closeCode: closeCode.rawValue))
        }
    }

}
