//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension SwitchUserState {
    
    // swiftlint:disable:next nesting
    struct Resolver: StateMachineResolver {
        typealias StateType = SwitchUserState
        let defaultState = SwitchUserState.notStarted

        
        // swiftlint:disable:next cyclomatic_complexity
        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            
            guard let switchEvent = event as? SwitchUserEvent else {
                return .from(oldState)
            }

            if case SwitchUserEvent.EventType.resetState = switchEvent.eventType {
                return .from(.notStarted)
            }
            
            switch oldState {
                
            case .notStarted:
                
                if case SwitchUserEvent.EventType.prepareForUserSwitch = switchEvent.eventType {
                    return self.resolveNotStartedState()
                } else if case SwitchUserEvent.EventType.switchToUser(let key) = switchEvent.eventType {
                    return self.resolveSwitchToUser(key: key)
                }
                return .from(oldState)
            case .fetchingCurrentSession:
                
                if case SwitchUserEvent.EventType.credentialsFetched(let amplifyCredentials, _, let isSigningIn) = switchEvent.eventType, case AmplifyCredentials.userPoolOnly(let signedInData) = amplifyCredentials, !isSigningIn {
                    return self.resolveCredintailsFetchedState(signedInData: signedInData)
                }
                return .from(oldState)
                
            case .storingCurrentSession(let signedInData):
                
                if case SwitchUserEvent.EventType.credentialsStored = switchEvent.eventType {
                    return self.resolveSessionStoredState(signedInData)
                }
                return .from(oldState)
                
            case .readyToSwitch:
                return .from(oldState)
            case .switchToUser:
                
                if case SwitchUserEvent.EventType.switchToUser(let key) = switchEvent.eventType {
                    return self.resolveSwitchToUser(key: key)
                }
                return .from(oldState)
            case .retrieveUser:
            
                if case SwitchUserEvent.EventType.credentialsStored = switchEvent.eventType {
                    return .init(newState: .sessionEstablished)
                }
                
                return .from(oldState)
            case .sessionEstablished:
                return .from(oldState)
            case .error:
                return .from(oldState)
            }
            return .from(oldState)
        }

        private func resolveNotStartedState() -> StateResolution<StateType> {
            let action = FetchSwitchUserCredentials(userKey: nil, isSigningIn: false)
            return .init(newState: .fetchingCurrentSession, actions: [action])
        }
        
        private func resolveCredintailsFetchedState(signedInData: SignedInData) -> StateResolution<StateType> {
            let action = StoreSwitchUserCredentials(signedInData: signedInData, userKey: signedInData.username)
            return .init(newState: .storingCurrentSession(signedInData), actions: [action])
        }
        
        private func resolveSessionStoredState(_ signedInData: SignedInData) -> StateResolution<StateType> {

            return .init(newState: .readyToSwitch(signedInData.username))
        }
        
        private func resolveSwitchToUser(key: String) -> StateResolution<StateType> {
            let action = FetchSwitchUserCredentials(userKey: key, isSigningIn: true)
            return .init(newState: .retrieveUser, actions: [action])
        }
        
        
    }
}
