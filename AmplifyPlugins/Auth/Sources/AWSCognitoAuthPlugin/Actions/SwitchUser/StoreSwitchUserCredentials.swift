//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct StoreSwitchUserCredentials: Action {

    let identifier = "StoreSwitchUserCredentials"
    
    let signedInData: SignedInData
    let userKey: String?

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
        let credentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)

        do {
            
            if let userKey = self.userKey {
                // Store credentials using the high-level client interface
                try await credentialStoreClient.storeData(data: .amplifyCredentials(credentials), key: userKey)
                
                let event = SwitchUserEvent(eventType: .credentialsStored(userKey, credentials, isPrepareToSwitch: true))
                logVerbose("\(#fileID) Sending success event - Credentials stored for user: \(userKey)", environment: environment)
                await dispatcher.send(event)
            } else {
                // Store credentials using the high-level client interface
                try await credentialStoreClient.storeData(data: .amplifyCredentials(credentials))
                
                let event = SwitchUserEvent(eventType: .credentialsStored("", credentials, isPrepareToSwitch: false))
                logVerbose("\(#fileID) Sending success event - Credentials stored for user: \(userKey)", environment: environment)
                await dispatcher.send(event)
            }
            
        } catch {
            let event = SwitchUserEvent(eventType: .switchUserError(
                AuthError.unknown("Failed to store credentials: \(error)")
            ))
            logVerbose("\(#fileID) Sending error event - Failed to store credentials: \(error)", environment: environment)
            await dispatcher.send(event)
        }
    }
}

extension StoreSwitchUserCredentials: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }

    var log: Logger {
        Self.log
    }
}

extension StoreSwitchUserCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "userKey": userKey,
            "username": signedInData.username
        ]
    }
}

extension StoreSwitchUserCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
