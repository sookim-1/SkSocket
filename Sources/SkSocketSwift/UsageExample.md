#  UsageExample

```swift
import Foundation
import Combine
import SkSocketSwift

final class WebSocketConnection: NSObject {

    static let shared = WebSocketConnection()

    private let skClient: SkSocketClient
    private var pingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        self.skClient = SkSocketClient(url: "ws://localhost.com:8080")

        super.init()
  }

    func buildConnection() {
        if self.skClient.isConnected() {
            return
        }

        self.skClient.onConnectSubject
            .sink { [weak self] isConnect in
                guard let self
                else { return }

                if isConnect {
                    self.startPingTimer()

                    Task { [weak self] in
                        guard let self else { return }
                        await self.openAndConsumeWebSocketConnection()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.skClient.connect()
                    }
                }
            }
            .store(in: &cancellables)

        skClient.connect()
    }

    public func openAndConsumeWebSocketConnection() async {
        do {
            if self.skClient.isConnected() {
                for try await message in self.skClient.receiveSocket() {
                    let str = String(decoding: message, as: UTF8.self)
                    print("💬 Received message: \(str)")
                }
            }
        } catch {
            print("Error receiving messages: \(error)")
        }
    }

    private func startPingTimer() {
        self.stopPingTimer()

        self.pingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            guard let self
            else { return }

            self.skClient.sendPing()
        }
    }

    private func stopPingTimer() {
        self.pingTimer?.invalidate()
        self.pingTimer = nil
    }

}

WebSocketConnection.shared.buildConnection()
```
