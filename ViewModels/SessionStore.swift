//
//  SessionStore.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import Foundation
import FirebaseAuth
import Combine

class SessionStore: ObservableObject {
    @Published var user: FirebaseAuth.User?

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        listen()
    }

    func listen() {
        authHandle = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            self.user = result?.user
            completion(error)
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            self.user = result?.user
            completion(error)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.user = nil
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
