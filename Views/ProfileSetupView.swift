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
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color("MutedGreenLight"), Color("MutedGreenDark")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text(isNewUser ? "Complete your profile" : "Edit profile")
                    .font(.custom("Georgia", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(Color(.darkGray))
                    .multilineTextAlignment(.center)
                    .padding(.top)

                if isLoadingProfile {
                    ProgressView()
                        .padding()
                } else {
                    Group {
                        TextField("Username (required)", text: $username)
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .font(.system(size: 16, design: .rounded))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bio")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.secondary)

                            TextEditor(text: $bio)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal)
                }

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
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
                        Text(isNewUser ? "Create profile" : "Save changes")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("MutedGreenAccent"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(username.isEmpty || isLoading || isLoadingProfile)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(isNewUser)
        .onAppear {
            if !isNewUser {
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
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let db = Firestore.firestore()

        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            isLoading = false

            if let error = error {
                self.error = "Error saving profile: \(error.localizedDescription)"
                if isNewUser {
                    session.signOut()
                    onComplete(false)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete(true)
                }
            }
        }
    }
}
