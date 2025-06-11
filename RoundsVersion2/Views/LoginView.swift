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
                        
                        if viewModel.error != nil {
                            Text(viewModel.error ?? "")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.login(email: email, password: password)
                            }
                        }) {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .primaryButton()
                        .padding(.horizontal)
                        
                        Button(action: { showingSignUp = true }) {
                            Text("Don't have an account? Sign Up")
                                .foregroundColor(AppColors.highlightBlue)
                        }
                    }
                    .padding(.top, 32)
                }
                .padding()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 