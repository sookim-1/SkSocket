//
//  File.swift
//  ScClientNative
//
//  Created by sookim on 10/28/24.
//

import Foundation

// eventName, error, data
public typealias AckEventNameHandler = (String, AnyObject?, AnyObject?) -> Void

// error, data
public typealias AckHandler = (AnyObject?, AnyObject?) -> Void

// eventName, data
public typealias OnEventHandler = (String, AnyObject?) -> Void

// eventName, data, ack
public typealias AckOnEventHandler = (String, AnyObject?, AckHandler) -> Void

public enum WebSocketError: Error {

    case invalid
    case normalClosure
    case goingAway
    case protocolError
    case unsupportedData
    case noStatusReceived
    case abnormalClosure
    case invalidFramePayloadData
    case policyViolation
    case messageTooBig
    case mandatoryExtensionMissing
    case internalServerError
    case tlsHandshakeFailure


    static func findMatchError(closeCode: Int) -> Self {
        switch closeCode {
        case 0: return .invalid
        case 1000: return .normalClosure
        case 1001: return .goingAway
        case 1002: return .protocolError
        case 1003: return .unsupportedData
        case 1005: return .noStatusReceived
        case 1006: return .abnormalClosure
        case 1007: return .invalidFramePayloadData
        case 1008: return .policyViolation
        case 1009: return .messageTooBig
        case 1010: return .mandatoryExtensionMissing
        case 1011: return .internalServerError
        case 1015: return .tlsHandshakeFailure
        default: return .invalid
        }
    }

}
