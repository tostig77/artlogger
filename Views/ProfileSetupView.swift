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
    @State private var isLoadingProfile = false
    
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
            
            if isLoadingProfile {
                ProgressView()
                    .padding()
            } else {
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
            }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
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
            .disabled(username.isEmpty || isLoading || isLoadingProfile)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(isNewUser) // Can't go back if new user
        .onAppear {
            if !isNewUser {
                // Load existing profile data when editing
                loadUserProfile()
            }
        }
    }
    
    func loadUserProfile() {
        guard let userId = session.user?.uid else {
            error = "Not logged in"
            return
        }
        
        isLoadingProfile = true
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            isLoadingProfile = false
            
            if let error = error {
                self.error = "Failed to load profile: \(error.localizedDescription)"
                return
            }
            
            if let data = snapshot?.data() {
                // Set the form fields with existing data
                username = data["username"] as? String ?? ""
                bio = data["bio"] as? String ?? ""
            }
        }
    }
    
    func saveProfile() {
        guard !username.isEmpty else {
            error = "Username is required"
            return
        }
        
        isLoading = true
        error = nil
        
        guard let user = session.user else {
            error = "Not logged in"
            isLoading = false
            return
        }
        
        let userData: [String: Any] = [
            "username": username,
            "bio": bio,
            "updatedAt": FieldValue.serverTimestamp() // Add a timestamp for the last update
        ]
        
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            isLoading = false
            
            if let error = error {
                self.error = "Error saving profile: \(error.localizedDescription)"
                
                // If we fail to create profile for a new user, we might want to sign them out
                if isNewUser {
                    session.signOut()
                    onComplete(false)
                }
            } else {
                // Success
                // Add a small delay to ensure Firestore write is completed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete(true)
                }
            }
        }
    }
}
