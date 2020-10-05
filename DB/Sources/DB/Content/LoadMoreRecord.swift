// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct LoadMoreRecord: Codable, Hashable {
    let timelineId: String
    let afterStatusId: String
    let beforeStatusId: String
}

extension LoadMoreRecord {
    enum Columns {
        static let timelineId = Column(LoadMoreRecord.CodingKeys.timelineId)
        static let afterStatusId = Column(LoadMoreRecord.CodingKeys.afterStatusId)
        static let beforeStatusId = Column(LoadMoreRecord.CodingKeys.beforeStatusId)
    }
}

extension LoadMoreRecord: FetchableRecord, PersistableRecord {
    static func databaseJSONDecoder(for column: String) -> JSONDecoder {
        MastodonDecoder()
    }

    static func databaseJSONEncoder(for column: String) -> JSONEncoder {
        MastodonEncoder()
    }
}