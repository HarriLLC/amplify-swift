//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Amplify
import AWSPluginsCore
import Foundation

class AWSSwitchToUserTask: DefaultLogger {

    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authConfiguration: AuthConfiguration
    private let userKey: String
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInAPI
    }

    init(authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration, userKey: String) {
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
        self.userKey = userKey
    }

    func execute() async throws -> AuthPrepareUserSwitchResult {
        await taskHelper.didStateMachineConfigured()
        // Check if we have a user pool configuration
        guard let userPoolConfiguration = authConfiguration.getUserPoolConfiguration() else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "Could not find user pool configuration",
                message)
            throw authError
        }

        try await validateCurrentState()
        
        do {
            log.verbose("Prepare to switch to new user")
            let result = try await doSwitch()
            log.verbose("Received result")
            return result
        } catch {
            throw error
        }
    }

    private func doSwitch() async throws -> AuthPrepareUserSwitchResult {
        log.verbose("Sending switcing event")
        
        let resetEvent = SwitchUserEvent(eventType: .resetState)
        await authStateMachine.send(resetEvent)
        
        await sendSwitchToUserEvent()
        
        log.verbose("Waiting for switching to complete")
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authNState, let authZState, _, let switchUserState) = state else { continue }

            if case AuthenticationState.signedIn(_) = authNState, case SwitchUserState.sessionEstablished = switchUserState {
                return AWSCognitoPrepareUserSwitchResult.complete("")
            }
            
            if case AuthenticationState.error(let error) = authNState {
                return AWSCognitoPrepareUserSwitchResult.failed(AuthError(error: error) )
            }
            
            if case SwitchUserState.error(let error) = switchUserState {
                return AWSCognitoPrepareUserSwitchResult.failed(AuthError(error: error) )
            }
        }
        throw AuthError.unknown("Prepare To Switch reached an error state")
    }

    private func validateCurrentState() async throws {

        let stateSequences = await authStateMachine.listen()
        log.verbose("Validating current state")
        for await state in stateSequences {
            guard case .configured(let authenticationState, _, _, _) = state else {
                continue
            }

            switch authenticationState {
            case .signedOut:
                return
            case .signedIn, .signingIn:
                let error = AuthError.invalidState(
                    "There is already a user in signedIn state. SignOut the user first before calling switch to user",
                    AuthPluginErrorConstants.invalidStateError, nil
                )
                throw error
            default:
                let error = AuthError.invalidState(
                    "Invalid state",
                    AuthPluginErrorConstants.invalidStateError, nil
                )
                throw error
            }
        }
    }
    
    private func sendSwitchToUserEvent() async {
        let event = SwitchUserEvent(eventType: .switchToUser(self.userKey))
        await authStateMachine.send(event)
    }

    

}
