import Foundation

// MARK: - Model
public class EmitEvent<T: Encodable>: Encodable {
    var event: String
    var data: T?
    var cid: Int

    init(event: String, data: T? = nil, cid: Int) {
        self.event = event
        self.data = data
        self.cid = cid
    }
}

public class AuthChannel: Encodable {
    var channel: String

    init(channel: String) {
        self.channel = channel
    }
}

// isConnected(), connect(), disconnect(), setBasicListener, subscribe, onChannel, unsubscribe

// MARK: - Main
public class SkSocketClient: NSObject {

    // MARK: - Listner
    typealias OnListenerHandler = (String, AnyObject?) -> Void

    var onListener: [String : OnListenerHandler] = [:]


    // MARK: - Origin
    public typealias OnConnectHandler = (SkSocketClient) -> Void
    public typealias OnConnectErrorHandler = ((SkSocketClient, Error?)-> Void)

    var url : String?
    var onConnect: OnConnectHandler?
    var onConnectError: OnConnectErrorHandler?
    var onDisconnect: OnConnectErrorHandler?
    var counter: AtomicInteger = AtomicInteger()

    // MARK: - WebSocket
    var socket: URLSessionWebSocketTask

    public init(url: String) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            self.socket = URLSession.shared.webSocketTask(with: request)
        } else {
            self.socket = URLSession.shared.webSocketTask(with: URL(string: "")!)
        }

        super.init()
    }

    deinit {
        self.socket.cancel(with: .goingAway, reason: nil)
    }

    public func setBasicListener(onConnect: OnConnectHandler?, onConnectError: OnConnectErrorHandler?, onDisconnect: OnConnectErrorHandler?) {
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onConnectError = onConnectError
    }

    public func connect() {
        socket.resume()
    }

    public func isConnected() -> Bool {
        return socket.state == .running
    }

    public func disconnect() {
        socket.cancel()
    }

    public func subscribe(channelName: String) throws {
        let subscribeObject = EmitEvent(event: "#subscribe", data: AuthChannel(channel: channelName), cid: counter.incrementAndGet())

        Task {
            do {
                try await self.send(subscribeObject)
            } catch {
                print("🚨 Websocket subscribe error: \(error.localizedDescription)")
                throw error
            }
        }
    }

    public func unsubscribe(channelName: String) throws {
        let unsubscribeObject = EmitEvent(event: "#unsubscribe", data: channelName, cid: counter.incrementAndGet())

        Task {
            do {
                try await self.send(unsubscribeObject)
            } catch {
                print("🚨 Websocket unsubscribe error: \(error.localizedDescription)")
                throw error
            }
        }
    }

    public func onChannel(channelName: String, ack: @escaping (String, AnyObject?) -> Void) {
        self.putOnListener(eventName: channelName, onListener: ack)
    }

    func putOnListener(eventName:  String, onListener: @escaping (String, AnyObject?) -> Void) {
        self.onListener[eventName] = onListener
    }

}

// MARK: - WebSocket Receive
extension SkSocketClient {

    // FIXME: socket-cluster subscribe -> send
    func send<T: Encodable>(_ message: T) async throws {
        guard let messageData = message.toJSONString()
        else { throw SKSocketConnectionError.encodingError }

        do {
            try await socket.send(.string(messageData))
        } catch {
            switch socket.closeCode {
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
    func receive() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { [weak self] in
            guard let self
            else { return nil }

            let message = try await self.receiveOnce()

            return Task.isCancelled ? nil : message
        }
    }

    func receiveOnce() async throws -> Data {
        do {
            return try await receiveSingleMessage()
        } catch let error as SKSocketConnectionError {
            throw error
        } catch {
            switch socket.closeCode {
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
        switch try await socket.receive() {
            case let .data(messageData):
                return messageData
            case let .string(text):
                guard let messageData = text.data(using: .utf8)
                else { throw SKSocketConnectionError.decodingError }

                return messageData
            @unknown default:
                self.socket.cancel(with: .unsupportedData, reason: nil)
                throw SKSocketConnectionError.decodingError
        }
    }
    

}

// MARK: - Integer
public final class AtomicInteger {

    private let lock = DispatchSemaphore(value: 1)
    private var _value: Int

    public init(value initialValue: Int = 0) {

        _value = initialValue
    }

    public var value: Int {
        get {
            lock.wait()
            defer { lock.signal() }
            return _value
        }
        set {
            lock.wait()
            defer { lock.signal() }
            _value = newValue
        }
    }

    public func decrementAndGet() -> Int {
        lock.wait()
        defer { lock.signal() }
        _value -= 1

        return _value
    }

    public func incrementAndGet() -> Int {
        lock.wait()
        defer { lock.signal() }
        _value += 1

        return _value
    }

}

// MARK: - Encodable Extension
public extension Encodable {

    func toJSONString(prettyPrint: Bool = false) -> String? {
        do {
            let encoder = JSONEncoder()

            if prettyPrint {
                encoder.outputFormatting = .prettyPrinted
            }

            let jsonData = try encoder.encode(self)

            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error converting to JSON String: \(error.localizedDescription)")
        }

        return nil
    }

}
