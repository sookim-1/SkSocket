import Testing
@testable import SkSocketSwift

struct SkSocketSwiftTests {

    @Test("JSON String 변환테스트")
    func convertJSONString() async throws {
        let counter = AtomicInteger()
        let sampleEmitEvent = EmitEvent(event: "#subscribe", data: AuthChannel(channel: "helloWorld"), cid: counter.incrementAndGet())

        #expect(sampleEmitEvent.toJSONString()! == nil)
    }

    @Test("localhost 테스트")
    func testLocalHostItem() async throws {
        let localhostAddress = "ws://127.0.0.1:8080/channel"
        let client = SkSocketClient(url: localhostAddress)
        client.connect()

        client.setBasicListener(onConnect: {
            Task {
                do {
                    for try await message in client.receiveSocket() {
                        let str = String(decoding: message, as: UTF8.self)
                        #expect(str == nil)
                    }
                } catch {
                    #expect(error == nil)
                }
            }
        }, onDisconnect: { 
            client.connect()
        })
    }

}
