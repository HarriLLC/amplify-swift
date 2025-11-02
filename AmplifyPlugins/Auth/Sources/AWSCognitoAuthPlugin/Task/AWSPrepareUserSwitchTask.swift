//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

class AWSPrepareUserSwitchTask: DefaultLogger {

    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authConfiguration: AuthConfiguration

    init(authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
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
            let result = try await doPrepare()
            log.verbose("Received result")
            return result
        } catch {
            throw error
        }
    }

    private func doPrepare() async throws -> AuthPrepareUserSwitchResult {
        log.verbose("Sending prepare to switch event")
        
        let resetEvent = SwitchUserEvent(eventType: .resetState)
        await authStateMachine.send(resetEvent)
        
        await sendPrepareForUserSwitchEvent()
        
        log.verbose("Waiting for signin to complete")
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authNState, let authZState, _, let switchUserState) = state else { continue }

            if case AuthenticationState.signedOut(_) = authNState, case SwitchUserState.readyToSwitch(let key) = switchUserState {
                return AWSCognitoPrepareUserSwitchResult.complete(key)
            }
            
            if case AuthenticationState.error(let error) = authNState {
                return AWSCognitoPrepareUserSwitchResult.failed(AuthError(error: error))
            }
            
            if case SwitchUserState.error(let error) = switchUserState {
                return AWSCognitoPrepareUserSwitchResult.failed(AuthError(error: error))
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
            case .signedOut, .configured, .signingIn:
                let error = AuthError.invalidState(
                    "Sign In the user first before calling Switch",
                    AuthPluginErrorConstants.invalidStateError, nil
                )
                throw error
            case .signedIn:
                return
            default:
                let error = AuthError.invalidState(
                    "Invalid state",
                    AuthPluginErrorConstants.invalidStateError, nil
                )
                throw error
            }
        }
    }

    private func sendPrepareForUserSwitchEvent() async {
        let event = SwitchUserEvent(eventType: .prepareForUserSwitch)
        await authStateMachine.send(event)
    }
}
