//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public enum AWSCognitoPrepareUserSwitchResult: AuthPrepareUserSwitchResult {

    case complete(String)

    case failed(AuthError)
}

extension AWSCognitoPrepareUserSwitchResult: Sendable { }
