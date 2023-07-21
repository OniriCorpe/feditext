// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import HTTP
import Mastodon

/// Thrown when an API is not available according to detected server software and version.
public struct APINotAvailableError: Error, LocalizedError, Encodable {
    public let method: String?
    public let url: URL?
    public let requestLocation: DebugLocation
    public let apiCapabilities: APICapabilities

    public init(
        method: String?,
        url: URL?,
        requestLocation: DebugLocation,
        apiCapabilities: APICapabilities
    ) {
        self.method = method
        self.url = url
        self.requestLocation = requestLocation
        self.apiCapabilities = apiCapabilities
    }

    public init(
        target: Target,
        requestLocation: DebugLocation,
        apiCapabilities: APICapabilities
    ) {
        let request = target.urlRequest()
        self.init(
            method: request.httpMethod,
            url: request.url,
            requestLocation: requestLocation,
            apiCapabilities: apiCapabilities
        )
    }

    public var errorDescription: String? {
        guard let method = method, let url = url else { return nil }

        return "\(method) \(url.absoluteString)"
    }
}
