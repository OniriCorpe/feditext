// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Tag: Codable {
    public let name: String
    public let url: UnicodeURL
    public let history: [History]?
}

public extension Tag {
    struct History: Codable, Hashable {
        public let day: String
        public let uses: String
        public let accounts: String
    }
}

extension Tag: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
