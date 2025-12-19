import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var errorMessage = ""
    @AppStorage("hasSignedInBefore") private var hasSignedInBefore = false
    
    var body: some View {
        if isLoggedIn {
            ContentView()
        } else {
            VStack(spacing: 20) {
                Spacer()
                
                Text("Gymmando")
                    .font(.largeTitle)
                    .bold()
                                
                
                Spacer()
                
                // Email/Password section
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button("Sign In") {
                        signIn()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    
                    Button("Create Account") {
                        createAccount()
                    }
                    .foregroundColor(.blue)
                    .font(.subheadline)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("or")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal, 32)
                
                // Google Sign-In
                GoogleSignInButton(action: signInWithGoogle)
                    .frame(height: 50)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
            .onAppear {
                // Always try Face ID first when app opens
                authenticateWithBiometric()
            }
        }
    }
    
    func authenticateWithBiometric() {
        BiometricAuth.shared.authenticate { success, error in
            if success {
                isLoggedIn = true
            } else {
                errorMessage = "Authentication failed"
            }
        }
    }
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                          accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    isLoggedIn = true
                    hasSignedInBefore = true
                }
            }
        }
    }
    
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                isLoggedIn = true
                hasSignedInBefore = true
            }
        }
    }
    
    func createAccount() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                isLoggedIn = true
                hasSignedInBefore = true
            }
        }
    }
}
