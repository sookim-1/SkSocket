//
//  File.swift
//  SkSocketSwift
//
//  Created by sookim on 10/24/24.
//

import Foundation

// MARK: - Model
class EmitEvent<T: Encodable>: Encodable {

    var event: String
    var data: T?
    var cid: Int

    init(event: String, data: T?, cid : Int) {
        self.event = event
        self.data = data
        self.cid = cid
    }

}

class ReceiveEvent<T: Encodable, U: Encodable>: Encodable {

    var data: T?
    var error: U?
    var rid: Int

    init (data: T?, error: U?, rid: Int) {
        self.data = data
        self.error = error
        self.rid = rid
    }

}

class Channel<T: Encodable>: Encodable {

    var channel: String
    var data: T?

    init (channel: String, data: T?) {
        self.channel = channel
        self.data = data
    }

}

class AuthChannel: Encodable {

    var channel: String
    var data: ChannelData?

    init(channel: String, token: String?) {
        self.channel = channel
        self.data = ChannelData(jwt: token)
    }

}

class ChannelData: Encodable {

    var jwt: String?

    init(jwt: String?) {
        self.jwt = jwt
    }

}

class HandShake: Encodable {

    var event: String
    var data: AuthData
    var cid: Int


    init(event: String, data: AuthData, cid: Int) {
        self.event = event
        self.data = data
        self.cid = cid
    }

}

class AuthData: Encodable {

    var authToken: String?

    init(authToken: String?) {
        self.authToken = authToken
    }

}

class Model  {

    public static func getEmitEventObject<T: Encodable>(eventName: String, data: T?, messageId: Int) -> EmitEvent<T> {
        return EmitEvent(event: eventName, data: data, cid: messageId)
    }

    public static func getReceiveEventObject<T: Encodable, U: Encodable>(data: T?, error: U?, messageId: Int) -> ReceiveEvent<T, U> {
        return ReceiveEvent(data: data, error: error, rid: messageId)
    }

    public static func getChannelObject(channelName: String, data: String) -> Channel<String>? {
        return Channel(channel: channelName, data: data)
    }

    public static func getSubscribeEventObject<T: Encodable>(channelName: String, messageId: Int, data: T? = nil) -> EmitEvent<Channel<T>> {
        return EmitEvent(event: "#subscribe", data: Channel(channel: channelName, data: data), cid: messageId)
    }

    public static func getSubscribeEventObject(channelName: String, messageId: Int, token: String? = nil) -> EmitEvent<AuthChannel> {
        return EmitEvent(event: "#subscribe", data: AuthChannel(channel: channelName, token: token), cid: messageId)
    }

    public static func getUnsubscribeEventObject(channelName: String, messageId: Int) -> EmitEvent<String> {
        return EmitEvent(event: "#unsubscribe", data: channelName, cid: messageId)
    }

    public static func getPublishEventObject<T: Encodable>(channelName: String, data: T?, messageId: Int) -> EmitEvent<Channel<T>> {
        return EmitEvent(event: "#publish", data: Channel(channel: channelName, data: data), cid: messageId)
    }

    public static func getHandshakeObject(authToken: String?, messageId: Int) -> HandShake {
        return HandShake(event: "#handshake", data: AuthData(authToken: authToken), cid: messageId)
    }

}
