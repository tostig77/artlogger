import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    var onSignupComplete: (Bool) -> Void = { _ in }

    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var navigateToSignup = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = error {
                Text(error).foregroundColor(.red)
            }

            Button("Login") {
                session.signIn(email: email, password: password) { err in
                    if let err = err {
                        error = err.localizedDescription
                    }
                    // For regular login, no profile setup needed
                    onSignupComplete(false)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            NavigationLink(
                destination: SignupView(onComplete: { needsProfileSetup in
                    // This will be called when signup is complete
                    onSignupComplete(needsProfileSetup)
                })
                .environmentObject(session),
                isActive: $navigateToSignup
            ) {
                Button("Don't have an account? Sign Up") {
                    navigateToSignup = true
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .navigationTitle("Login")
    }
}
