# ScClientNative
A lightweight, native iOS/macOS client written in Swift for connecting to SocketCluster servers, with no third-party dependencies.

## Overview
--------
This version of the SocketCluster client library is designed to minimize dependencies, replacing Starscream with URLSessionWebSocketTask and removing HandyJSON entirely. It supports the essential functionality of the original library, such as:
- Quick and simple setup
- Emission and listening for remote events
- Pub/sub functionality
- JWT-based authentication

Compatible platforms:
- iOS >= 15.0
- macOS >= 12.0

## Installation

## Swift Package Manager
Add the following to the dependencies section of your Package.swift:


 ```swift
dependencies: [
    .package(url: "https://github.com/sookim-1/socketcluster-client-swift-native.git", from: "1.0.7")
]
```

- To use the library, include it in your target dependencies:

 ```swift
targets: [
    .target(
        name: "your_target",
        dependencies: [
            "ScClientNative"
        ]
    )
]
```

## Getting Started
### Initializing the Client
Create an instance of ScClient by providing the URL of your SocketCluster server endpoint:

```swift
// Instantiate the client
let client = ScClient(url: "ws://yourserver.com/socketcluster/")
```

### Connecting to the Server
To initiate a WebSocket connection:

```swift
client.connect()
```

### Listening for Events
Register listeners to handle connection events:

```swift
let onConnect = { (client: ScClient) in
    print("Connected to the server")
}

let onDisconnect = { (client: ScClient, error: Error?) in
    print("Disconnected from server:", error?.localizedDescription ?? "No error")
}

client.setBasicListener(onConnect: onConnect, onConnectError: nil, onDisconnect: onDisconnect)
```

### Emitting Events
To emit events to the server:

```swift
client.emit(eventName: "yourEvent", data: "Hello, World!")
```

To send an event with acknowledgment:

```swift
client.emitAck(eventName: "yourEvent", data: "Hello again!") { (eventName, error, data) in
    print("Response for event \(eventName):", data ?? "No data")
}
```

### Subscribing to Channels
To subscribe to channels:

```swift
client.subscribe(channelName: "yourChannel")
```

With acknowledgment:

```swift
client.subscribeAck(channelName: "yourChannel") { (channelName, error, data) in
    if error == nil {
        print("Subscribed to \(channelName)")
    } else {
        print("Subscription error:", error ?? "Unknown error")
    }
}
```

### Receiving Channel Events
To receive messages from a channel:

```swift
client.onChannel(channelName: "yourChannel") { (channelName, data) in
    print("Received on \(channelName):", data ?? "No data")
}
```

### Unsubscribing from Channels
To unsubscribe:

```swift
client.unsubscribe(channelName: "yourChannel")
```

## Customization Options
### Protocols
Specify WebSocket protocols if required:

```swift
let client = ScClient(url: "ws://yourserver.com/socketcluster/", protocols: ["protocol1", "protocol2"])
```
