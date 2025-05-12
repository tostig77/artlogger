import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore

    @State private var email = ""
    @State private var password = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
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
                }
            }

            NavigationLink("Don't have an account? Sign Up", destination: SignupView())
                .foregroundColor(.blue) // You can explicitly set the color here as well
        }
        .padding()
        .navigationTitle("Login")
    }
}
