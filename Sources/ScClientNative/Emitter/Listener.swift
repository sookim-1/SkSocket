//
//  Listener.swift
//  ScClientNative
//
//  Created by sookim on 10/28/24.
//

import Foundation

public class Listener: NSObject {

    var emitAckListener: [Int: (String, AckHandler)]
    var onListener: [String: (String, AnyObject?) -> Void]
    var onAckListener: [String: (String, AnyObject?, (AnyObject?, AnyObject?) -> Void) -> Void]

    public override init() {
        emitAckListener = [Int : (String, AckHandler)]()
        onListener = [String : (String, AnyObject?) -> Void]()
        onAckListener = [String: (String, AnyObject?, (AnyObject?, AnyObject?) -> Void) -> Void]()
    }

    func putEmitAck(id: Int, eventName: String, ack: @escaping AckHandler) {
        self.emitAckListener[id] = (eventName, ack)
    }

    func handleEmitAck(id: Int, error: AnyObject?, data: AnyObject?) {
        if let ackobject = emitAckListener[id] {
            let eventName = ackobject.0
            let ack = ackobject.1
            ack(eventName, error, data)
        }
    }

    func putOnListener(eventName: String, onListener: @escaping (String, AnyObject?) -> Void) {
        self.onListener[eventName] = onListener
    }

    func handleOnListener(eventName: String, data: AnyObject?) {
        if let on = onListener[eventName] {
            on(eventName, data)
        }
    }

    func putOnAckListener(eventName: String, onAckListener: @escaping (String, AnyObject?, (AnyObject?, AnyObject?) -> Void ) -> Void) {
        self.onAckListener[eventName] = onAckListener
    }

    func handleOnAckListener(eventName: String, data: AnyObject?, ack: (AnyObject?, AnyObject?) -> Void) {
        if let onAck = onAckListener[eventName] {
            onAck(eventName, data, ack)
        }
    }

    func hasEventAck(eventName: String) -> Bool {
        return (onAckListener[eventName] != nil)
    }

}
