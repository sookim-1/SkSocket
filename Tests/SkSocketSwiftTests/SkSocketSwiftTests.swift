import Testing
@testable import SkSocketSwift

struct SkSocketSwiftTests {

    @Test("초기화 테스트")
    func initSkSocketClient() async throws {
        let localhostAddress = "ws://127.0.0.1:8080/channel"
        let client = SkSocketClient(url: papahostAddress)
        let counter = AtomicInteger()

        client.connect()

        #expect(client.isConnected())

        do {
            try client.subscribe(channelName: "dw")
        } catch {
            print("🚨 \(error.localizedDescription)")
        }

        do {
            try client.unsubscribe(channelName: "vv")
        } catch {
            print("🚨 \(error.localizedDescription)")
        }

        client.setBasicListener { client in
            client.socket?.receive(completionHandler: { result in
                switch result {
                case .success(let success):
                    print(success)
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            })
        } onConnectError: { client, error in
            client.socket?.receive(completionHandler: { result in
                switch result {
                case .success(let success):
                    print(success)
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            })
        } onDisconnect: { client, error in
            client.socket?.receive(completionHandler: { result in
                switch result {
                case .success(let success):
                    print(success)
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            })
        }

        print("👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉👉")
        #expect(client.socket == nil)
    }

    @Test("JSON String 변환테스트")
    func convertJSONString() async throws {
        let counter = AtomicInteger()
        let sampleEmitEvent = EmitEvent(event: "#subscribe", data: AuthChannel(channel: "helloWorld"), cid: counter.incrementAndGet())

        #expect(sampleEmitEvent.toJSONString()! == nil)
    }

}
