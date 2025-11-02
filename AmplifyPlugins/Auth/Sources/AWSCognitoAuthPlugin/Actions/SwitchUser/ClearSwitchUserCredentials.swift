//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct ClearSwitchUserCredentials: Action {

    let identifier = "ClearSwitchUserCredentials"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let authEnvironment = environment as? AuthEnvironment else {
            let event = SwitchUserEvent(eventType: .switchUserError(
                AuthError.configuration("Invalid environment", "Expected AuthEnvironment")
            ))
            logVerbose("\(#fileID) Sending error event - Invalid environment", environment: environment)
            await dispatcher.send(event)
            return
        }

        let credentialStoreClient = authEnvironment.credentialsClient

        do {
            try await credentialStoreClient.deleteData(type: .amplifyCredentials)
            
            let event = SwitchUserEvent(eventType: .credentialsCleared)
            logVerbose("\(#fileID) Sending success event - Credentials cleared", environment: environment)
            await dispatcher.send(event)
            
        } catch {
            let event = SwitchUserEvent(eventType: .switchUserError(
                AuthError.unknown("Failed to clear credentials: \(error)")
            ))
            logVerbose("\(#fileID) Sending error event - Failed to clear credentials: \(error)", environment: environment)
            await dispatcher.send(event)
        }
    }
}

extension ClearSwitchUserCredentials: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }

    var log: Logger {
        Self.log
    }
}

extension ClearSwitchUserCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ClearSwitchUserCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
