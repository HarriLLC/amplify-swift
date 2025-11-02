//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct SwitchUserEvent: StateMachineEvent {
    enum EventType: Equatable {

        /// prepare for user switch
        case prepareForUserSwitch
        
        /// Switch To User
        case switchToUser(String)
        
        /// Credentials fetched successfully
        case credentialsFetched(AmplifyCredentials, String?, isSigningIn: Bool)
        
        /// Credentials stored successfully
        case credentialsStored(String, AmplifyCredentials, isPrepareToSwitch: Bool)  // userKey
        
        /// Credentials cleared successfully
        case credentialsCleared
        
        /// Reset to not started
        case resetState
        
        /// Switch user error occurred
        case switchUserError(AuthError)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .prepareForUserSwitch:
            return "SwitchUserEvent.prepareForUserSwitch"
        case .switchToUser:
            return "SwitchUserEvent.switchToUser"
        case .credentialsFetched:
            return "SwitchUserEvent.credentialsFetched"
        case .credentialsStored:
            return "SwitchUserEvent.credentialsStored"
        case .credentialsCleared:
            return "SwitchUserEvent.credentialsCleared"
        case .resetState:
            return "SwitchUserEvent.resetState"
        case .switchUserError:
            return "SwitchUserEvent.switchUserError"
        }
    }

    init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}
