//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

enum SwitchUserState: State {
    
    /// Not Started
    case notStarted
    
    /// Fetching Current Session
    case fetchingCurrentSession
    
    /// Store Current sesstion
    case storingCurrentSession(SignedInData)

    /// Ready To Switch
    case readyToSwitch(String)
    
    /// Switch To User
    case switchToUser

    /// Retrieve User
    case retrieveUser
    
    /// Establish Session
    case sessionEstablished
    
    /// System encountered an error
    case error(AuthenticationError)
}

extension SwitchUserState {

    var type: String {
        switch self {
            case .notStarted: return "SwitchUserState.signotStartednedIn"
            case .fetchingCurrentSession: return "SwitchUserState.fetchingCurrentSession"
            case .storingCurrentSession: return "SwitchUserState.storingCurrentSession"
            case .readyToSwitch: return "SwitchUserState.readyToSwitch"
            case .switchToUser: return "SwitchUserState.switchToUser"
            case .retrieveUser: return "SwitchUserState.retrieveUser"
            case .sessionEstablished: return "SwitchUserState.establishSession"
            case .error: return "ERROR"
        }
    }
}
