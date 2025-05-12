import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    var onSignupComplete: (Bool) -> Void = { _ in }

    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var navigateToSignup = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color("MutedGreenLight"), Color("MutedGreenDark")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                Text("Welcome to Artchive")
                    .font(.custom("Georgia", size: 34))
                    .fontWeight(.bold)
                    .foregroundColor(Color(.darkGray))
                    .multilineTextAlignment(.center)
                    .padding(.top)

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
                    session.signIn(email: email, password: password) { err in
                        if let err = err {
                            error = err.localizedDescription
                        }
                        onSignupComplete(false)
                    }
                }) {
                    Text("Log in")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("MutedGreenAccent"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.white)
                        .font(.system(size: 18, design: .rounded))

                    Button(action: {
                        navigateToSignup = true
                    }) {
                        Text("Sign up now!")
                            .foregroundColor(Color("MutedGreenAccent"))
                            .font(.system(size: 18, weight: .semibold, design: .default))
                    }
                }

                NavigationLink(
                    destination: SignupView(onComplete: { needsProfileSetup in
                        onSignupComplete(needsProfileSetup)
                    })
                    .environmentObject(session),
                    isActive: $navigateToSignup
                ) {
                    EmptyView()
                }
            }
            .padding(.horizontal, 30)
        }
        .navigationBarHidden(true)
    }
}
