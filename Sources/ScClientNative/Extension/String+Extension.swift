//
//  String+Extension.swift
//  SkSocketSwift
//
//  Created by sookim on 10/24/24.
//

import Foundation

extension String {

    func toWebSocketURL() -> String {
        if self.hasPrefix("https://") {
            return self.replacingOccurrences(of: "https://", with: "ws://")
        } else if self.hasPrefix("http://") {
            return self.replacingOccurrences(of: "http://", with: "ws://")
        } else {
            return self
        }
    }

}
