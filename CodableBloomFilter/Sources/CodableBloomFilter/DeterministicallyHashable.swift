// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol DeterministicallyHashable {
    var hashableData: Data { get }
}