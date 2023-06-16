// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum RulesEndpoint {
    case rules
}

extension RulesEndpoint: Endpoint {
    public typealias ResultType = [Rule]

    public var context: [String] {
        defaultContext + ["instance/rules"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .rules:
            return []
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .rules:
            return .get
        }
    }
}