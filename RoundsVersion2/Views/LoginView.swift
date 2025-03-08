import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundWhite
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Logo/Header
                    VStack(spacing: 16) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.primaryNavy)
                        
                        Text("Welcome to Rounds")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primaryNavy)
                    }
                    
                    // Login Form
                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        if let error = viewModel.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.login(email: email, password: password)
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Log In")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .navyButton()
                        .padding(.horizontal)
                        .disabled(viewModel.isLoading)
                        
                        Button(action: { showingSignUp = true }) {
                            Text("Don't have an account? Sign Up")
                                .foregroundColor(AppColors.highlightBlue)
                        }
                    }
                    .padding(.top, 32)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    LoginView()
} 