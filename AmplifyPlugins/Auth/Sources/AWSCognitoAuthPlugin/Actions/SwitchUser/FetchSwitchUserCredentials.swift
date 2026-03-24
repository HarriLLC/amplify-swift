//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct FetchSwitchUserCredentials: Action {

    let identifier = "FetchSwitchUserCredentials"
    
    let userKey: String?  // Optional: to fetch specific user's credentials
    let isSigningIn: Bool
    
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
            
            let data: CredentialStoreData!
            
            if let userKey = self.userKey {
                data = try await credentialStoreClient.fetchData(type: .amplifyCredentials, key: userKey)
            } else {
                data = try await credentialStoreClient.fetchData(type: .amplifyCredentials)
            }
            
            guard case .amplifyCredentials(let credentials) = data else {
                let event = SwitchUserEvent(eventType: .switchUserError(
                    AuthError.signedOut("No credentials found", "")
                ))
                logVerbose("\(#fileID) Sending error event - No credentials found", environment: environment)
                await dispatcher.send(event)
                return
            }
            
            let event = SwitchUserEvent(eventType: .credentialsFetched(credentials, self.userKey, isSigningIn: self.isSigningIn))
            logVerbose("\(#fileID) Sending success event - Credentials fetched", environment: environment)
            await dispatcher.send(event)
            
        } catch KeychainStoreError.itemNotFound {
            let event = SwitchUserEvent(eventType: .switchUserError(
                AuthError.signedOut("No credentials found", "")
            ))
            logVerbose("\(#fileID) Sending error event - Credentials not found in keychain", environment: environment)
            await dispatcher.send(event)
        } catch {
            let event = SwitchUserEvent(eventType: .switchUserError(
                AuthError.unknown("Failed to fetch credentials: \(error)")
            ))
            logVerbose("\(#fileID) Sending error event - Failed to fetch credentials: \(error)", environment: environment)
            await dispatcher.send(event)
        }
    }
}

extension FetchSwitchUserCredentials: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }

    var log: Logger {
        Self.log
    }
}

extension FetchSwitchUserCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "userKey": userKey ?? "default"
        ]
    }
}

extension FetchSwitchUserCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
