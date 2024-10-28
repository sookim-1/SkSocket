//
//  Encodable+Extension.swift
//  SkSocketSwift
//
//  Created by sookim on 10/24/24.
//

import Foundation

// MARK: - Encodable Extension
public extension Encodable {

    func toJSONString(prettyPrint: Bool = false) -> String? {
        do {
            let encoder = JSONEncoder()

            if prettyPrint {
                encoder.outputFormatting = .prettyPrinted
            }

            let jsonData = try encoder.encode(self)

            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error converting to JSON String: \(error.localizedDescription)")
        }

        return nil
    }

}
