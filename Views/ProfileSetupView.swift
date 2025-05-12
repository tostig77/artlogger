import SwiftUI
import Firebase
import FirebaseFirestore

struct ProfileSetupView: View {
    @EnvironmentObject var session: SessionStore
    
    var isNewUser: Bool
    var onComplete: (Bool) -> Void
    
    @State private var username = ""
    @State private var bio = ""
    @State private var error: String?
    @State private var isLoading = false
    @State private var debugMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isNewUser ? "Complete Your Profile" : "Edit Profile")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)
            
            if isNewUser {
                Text("Please set up your profile to continue")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
            }
            
            Group {
                TextField("Username (required)", text: $username)
                    .textFieldStyle(.roundedBorder)
                
                
                VStack(alignment: .leading) {
                    Text("Bio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if let debugMessage = debugMessage {
                Text("Debug: \(debugMessage)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding()
            }
            
            Spacer()
            
            Button(action: {
                saveProfile()
            }) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text(isNewUser ? "Create Profile" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(username.isEmpty || isLoading)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(isNewUser) // Can't go back if new user
        .onAppear {
            checkFirestoreStatus()
        }
    }
    
    func checkFirestoreStatus() {
        let firestore = Firestore.firestore()
        let testCollection = firestore.collection("test")
        let testId = UUID().uuidString
        
        debugMessage = "Testing Firestore connection..."
        
        testCollection.document(testId).setData(["timestamp": FieldValue.serverTimestamp()]) { error in
            if let error = error {
                debugMessage = "Firestore test failed: \(error.localizedDescription)"
            } else {
                debugMessage = "Firestore connection successful!"
                
                // Clean up test document
                testCollection.document(testId).delete()
            }
        }
    }
    
    func saveProfile() {
        guard !username.isEmpty else {
            error = "Username and Display Name are required"
            return
        }
        
        isLoading = true
        error = nil
        debugMessage = "Starting profile save..."
        
        guard let user = session.user else {
            error = "Not logged in"
            isLoading = false
            debugMessage = "Error: User not found in session"
            return
        }
        
        debugMessage = "User found: \(user.uid)"
        
        let userData: [String: Any] = [
            "username": username,
            "bio": bio,
        ]
        
        let db = Firestore.firestore()
        debugMessage = "Attempting to write to Firestore..."
        
        // Let's also add a print for debugging
        print("Writing to Firestore for user: \(user.uid) with data: \(userData)")
        
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            isLoading = false
            
            if let error = error {
                self.error = "Error saving profile: \(error.localizedDescription)"
                debugMessage = "Firestore write failed: \(error.localizedDescription)"
                
                // If we fail to create profile for a new user, we might want to sign them out
                if isNewUser {
                    session.signOut()
                    onComplete(false)
                }
            } else {
                // Success
                debugMessage = "Profile saved successfully!"
                
                // Add a small delay to ensure Firestore write is completed
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onComplete(true)
                }
            }
        }
    }
}
