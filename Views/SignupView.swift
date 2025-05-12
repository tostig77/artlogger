import SwiftUI
import Firebase

struct SignupView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    var onComplete: (Bool) -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var isLoading = false
    
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

            Button(action: {
                signUp()
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
        }
        .padding()
        .navigationTitle("Sign Up")
    }
    
    func signUp() {
        isLoading = true
        error = nil
        
        session.signUp(email: email, password: password) { err in
            isLoading = false
            if let err = err {
                error = err.localizedDescription
            } else {
                // Signal that profile setup is needed
                onComplete(true)
                // Go back to the entry view which will now show profile setup
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
