//
//  SKSocketConnectionError.swift
//  SkSocketSwift
//
//  Created by sookim on 10/23/24.
//

import Foundation

public enum SKSocketConnectionError: Error {
    case connectionError
    case transportError
    case encodingError
    case decodingError
    case disconnected
    case closed
}
