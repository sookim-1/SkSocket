import Foundation

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

public class SkSocketClient {

    // MARK: - Listner
    typealias EmitAckHandler = (String, AnyObject?, AnyObject?) -> Void
    typealias OnListenerHandler = (String, AnyObject?) -> Void
    typealias OnAckListenerHandler = (String, AnyObject?, (AnyObject?, AnyObject?) -> Void) -> Void

    var emitAckListener: [Int: (String, EmitAckHandler)] = [:]
    var onListener: [String : OnListenerHandler] = [:]
    var onAckListener: [String: OnAckListenerHandler] = [:]


    // MARK: - Origin
    public typealias OnConnectHandler = (SkSocketClient) -> Void
    public typealias OnConnectErrorHandler = ((SkSocketClient, Error?)-> Void)

    var url : String?
    var onConnect: OnConnectHandler?
    var onConnectError: OnConnectErrorHandler?
    var onDisconnect: OnConnectErrorHandler?
    var counter: AtomicInteger = AtomicInteger()

    // MARK: - WebSocket
    //  = URLSession.shared.webSocketTask(with: URL(string: )!)
    var socket: URLSessionWebSocketTask?

    public convenience init(url: String) {
        self.init()

        self.socket = URLSession.shared.webSocketTask(with: URL(string: url)!)
    }

    public func setBasicListener(onConnect: OnConnectHandler?, onConnectError: OnConnectErrorHandler?, onDisconnect: OnConnectErrorHandler?) {
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onConnectError = onConnectError
    }

    public func connect() {
        socket?.resume()
    }

    public func isConnected() -> Bool {
        return socket?.state == .running
    }

    public func disconnect() {
        socket?.cancel()
    }

    public func subscribe(channelName: String) async {
        let subscribeObject = EmitEvent(event: "#subscribe", data: AuthChannel(channel: channelName), cid: counter.incrementAndGet())

        do {
            try await self.socket?.send(.string(subscribeObject.toJSONString()!))
        } catch {
            print("\(error.localizedDescription)")
        }
    }

    public func unsubscribe(channelName: String) async {
        let unsubscribeObject = EmitEvent(event: "#unsubscribe", data: channelName, cid: counter.incrementAndGet())

        do {
            try await self.socket?.send(.string(unsubscribeObject.toJSONString()!))
        } catch {
            print("\(error.localizedDescription)")
        }
    }

    public func onChannel(channelName : String, ack : @escaping (String, AnyObject?) -> Void) {
        putOnListener(eventName: channelName, onListener: ack)
    }

    func putOnListener(eventName : String, onListener: @escaping (String, AnyObject?) -> Void) {
        self.onListener[eventName] = onListener
    }

}

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
