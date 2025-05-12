import SwiftUI
import Firebase

struct SignupView: View {
    @EnvironmentObject var session: SessionStore
    
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var isProfileSetup = false  // To track if profile setup is needed
    @State private var username = ""
    @State private var bio = ""
    @State private var screenName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            if isProfileSetup {
                // Profile creation view
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                TextField("Screen Name", text: $screenName)
                    .textFieldStyle(.roundedBorder)
                TextField("Bio", text: $bio)
                    .textFieldStyle(.roundedBorder)
                
                if let error = error {
                    Text(error).foregroundColor(.red)
                }
                
                Button("Create Profile") {
                    createProfile()
                }
                .padding()
            } else {
                // Regular sign-up view
                TextField("Email", text: $email).autocapitalization(.none).textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password).textFieldStyle(.roundedBorder)

                if let error = error {
                    Text(error).foregroundColor(.red)
                }

                Button("Sign Up") {
                    session.signUp(email: email, password: password) { err in
                        if let err = err {
                            error = err.localizedDescription
                        } else {
                            // If signup is successful, proceed to profile setup
                            isProfileSetup = true
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle(isProfileSetup ? "Create Profile" : "Sign Up")
    }

    func createProfile() {
        
        let db = Firestore.firestore()
        
        // Create a dictionary with the profile data
        let profileData: [String: Any] = [
            "username": username,
            "screenName": screenName,
            "bio": bio,
            "email": email
        ]
        
        // Save to Firestore
        db.collection("users").document(email).setData(profileData) { error in
            if let error = error {
                self.error = error.localizedDescription
            } else {
                // Redirect to profile or home page after profile creation
                print("Profile created successfully.")
            }
        }
    }
}
