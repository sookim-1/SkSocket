import Foundation
import Combine

// MARK: - Main
public class SkSocketClient: NSObject {

    public let onConnectSubject = PassthroughSubject<Bool, Never>()
    public var socket: URLSessionWebSocketTask?
    private var counter: AtomicInteger = AtomicInteger()
    private var url: String

    public init(url: String) {
        self.url = url

        super.init()
    }

    deinit {
        self.disconnect()
    }

    public func connect() {
        // WebSocketTask Init
        if let url = URL(string: self.url) {
            let request = URLRequest(url: url)
            self.socket = URLSession.shared.webSocketTask(with: request)
        } else {
            self.socket = URLSession.shared.webSocketTask(with: URL(string: "")!)
        }

        self.socket?.delegate = self
        self.socket?.resume()
    }


    public func isConnected() -> Bool {
        return socket?.state == .running
    }

    public func disconnect() {
        socket?.cancel()
        socket = nil
    }

    public func subscribe(channelName: String) async {
        let subscribeObject = EmitEvent(event: "#subscribe", data: AuthChannel(channel: channelName), cid: await counter.incrementAndGet())

        try? await self.send(subscribeObject)
    }

    public func unsubscribe(channelName: String) async {
        let unsubscribeObject = EmitEvent(event: "#unsubscribe", data: channelName, cid: await counter.incrementAndGet())

        try? await self.send(unsubscribeObject)
    }

    public func setHandshake() async {
        let handShakeObject = HandShake(event: "#handshake", cid: await counter.incrementAndGet())
        try? await self.send(handShakeObject)
    }

}

// MARK: - WebSocket Receive
extension SkSocketClient {

    // FIXME: socket-cluster subscribe -> send
    private func send<T: Encodable>(_ message: T) async throws {
        guard let messageData = message.toJSONString()
        else { throw SKSocketConnectionError.encodingError }

        do {
            try await socket?.send(.string(messageData))
        } catch {
            switch socket?.closeCode {
                case .invalid:
                    throw SKSocketConnectionError.connectionError
                case .goingAway:
                    throw SKSocketConnectionError.disconnected
                case .normalClosure:
                    throw SKSocketConnectionError.closed
                default:
                    throw SKSocketConnectionError.transportError
            }
        }
    }

    // FIXME: socket-cluster on channel -> receive
    public func receiveSocket() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { [weak self] in
            guard let self
            else { return nil }

            let message = try await self.receiveOnce()

            return Task.isCancelled ? nil : message
        }
    }

    private func receiveOnce() async throws -> Data {
        do {
            return try await receiveSingleMessage()
        } catch let error as SKSocketConnectionError {
            throw error
        } catch {
            switch socket?.closeCode {
                case .invalid:
                    throw SKSocketConnectionError.connectionError
                case .goingAway:
                    throw SKSocketConnectionError.disconnected
                case .normalClosure:
                    throw SKSocketConnectionError.closed
                default:
                    throw SKSocketConnectionError.transportError
            }
        }
    }

    private func receiveSingleMessage() async throws -> Data {
        switch try await socket?.receive() {
            case let .data(messageData):
                return messageData
            case let .string(text):
                guard let messageData = text.data(using: .utf8)
                else { throw SKSocketConnectionError.decodingError }

                return messageData
            @unknown default:
                self.disconnect()
                throw SKSocketConnectionError.decodingError
        }
    }
    
    public func sendPing() {
        self.socket?.sendPing(pongReceiveHandler: { error in
            if error != nil { print(error) }
        })
    }
}

// MARK: - URLSessionWebSocketDelegate
extension SkSocketClient: URLSessionWebSocketDelegate {

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task {
            await counter.setValue(0)
            await self.setHandshake()
            self.onConnectSubject.send(true)
        }
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.onConnectSubject.send(false)
    }

}
