import Testing
@testable import SkSocketSwift

@Test("JSON String 변환테스트")
func convertJSONString() async throws {
    let counter = AtomicInteger()
    let sampleEmitEvent = EmitEvent(event: "#subscribe", data: AuthChannel(channel: "helloWorld"), cid: counter.incrementAndGet())

    #expect(sampleEmitEvent.toJSONString()! == nil)
}
