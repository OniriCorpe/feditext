// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// https://docs.joinmastodon.org/methods/announcements/
public enum AnnouncementsEndpoint {
    case announcements
}

extension AnnouncementsEndpoint: Endpoint {
    public typealias ResultType = [Announcement]

    public var pathComponentsInContext: [String] {
        ["announcements"]
    }

    public var method: HTTPMethod {
        .get
    }

    public var requires: APICapabilityRequirements? {
        [
            .mastodon: "3.1.0",
            .hometown: "3.1.0",
            .pleroma: .assumeAvailable,
            .akkoma: .assumeAvailable
        ]
    }

    public var fallback: [Announcement]? { [] }
}
