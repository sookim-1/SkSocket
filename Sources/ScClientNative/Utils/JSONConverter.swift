//
//  File.swift
//  ScClientNative
//
//  Created by sookim on 10/28/24.
//

import Foundation

public class JSONConverter {

    public static func deserializeString(message: String) -> [String: Any]? {
        let jsonObject = try? JSONSerialization.jsonObject(with: message.data(using: .utf8)!, options: [])
        return jsonObject as? [String : Any]
    }

    public static func deserializeData(data: Data) -> [String: Any]? {
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [])
        return jsonObject as? [String : Any]
    }

    public static func serializeObject(object: Any) -> String? {
        let message = try? JSONSerialization.data(withJSONObject: object, options: [])
        return String(data: message!, encoding: .utf8)
    }

    public static func jsonString(from value: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(value) else { return nil }

        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to encode JSON: \(error.localizedDescription)")
            return nil
        }
    }

}

