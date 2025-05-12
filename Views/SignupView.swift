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
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color("MutedGreenLight"), Color("MutedGreenDark")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                // Custom back button
                HStack {
                    Button(action: {
                                            presentationMode.wrappedValue.dismiss()
                                        }) {
                                            Image(systemName: "chevron.left")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundColor(Color("MutedGreenAccent"))
                                                .padding(10)
                                                .clipShape(Circle())
                                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        }
                                        Spacer()
                }
                .padding(.top, 20)

                Text("Create an Artchive account")
                    .font(.custom("Georgia", size: 30))
                    .fontWeight(.bold)
                    .foregroundColor(Color(.darkGray))
                    .multilineTextAlignment(.center)

                VStack(spacing: 18) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .font(.system(size: 16, design: .rounded))

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .font(.system(size: 16, design: .rounded))
                }

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Button(action: {
                    signUp()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("MutedGreenAccent")))
                    } else {
                        Text("Sign up")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("MutedGreenAccent"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .navigationBarHidden(true)
    }

    func signUp() {
        isLoading = true
        error = nil

        session.signUp(email: email, password: password) { err in
            isLoading = false
            if let err = err {
                error = err.localizedDescription
            } else {
                onComplete(true)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
