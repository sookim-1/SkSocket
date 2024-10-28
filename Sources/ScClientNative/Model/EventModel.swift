//
//  File.swift
//  SkSocketSwift
//
//  Created by sookim on 10/24/24.
//

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


public class HandShake: Encodable {
    var event: String
    var cid: Int

    init(event: String, cid: Int) {
        self.event = event
        self.cid = cid
    }
}
