import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var isShowingSignUp = false
    @FocusState private var focusedField: Field?
    @State private var isSecureField = true
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo and Title
                    Image(systemName: "golf")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                    
                    Text("Rounds")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Login Form
                    VStack(spacing: 15) {
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .email)
                        
                        ZStack(alignment: .trailing) {
                            Group {
                                if isSecureField {
                                    SecureField("Password", text: $viewModel.password)
                                } else {
                                    TextField("Password", text: $viewModel.password)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.oneTimeCode) // This prevents password suggestions
                            .focused($focusedField, equals: .password)
                            
                            Button {
                                isSecureField.toggle()
                            } label: {
                                Image(systemName: isSecureField ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                        
                        Button {
                            Task {
                                await viewModel.login()
                            }
                        } label: {
                            Text("Login")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .disabled(viewModel.isLoading)
                        
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sign Up Button
                    Button("Don't have an account? Sign Up") {
                        isShowingSignUp = true
                    }
                    .sheet(isPresented: $isShowingSignUp) {
                        SignUpView()
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onTapGesture {
                focusedField = nil
            }
        }
    }
}

#Preview {
    LoginView()
} 