import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SignUpViewModel()
    @FocusState private var focusedField: Field?
    @State private var isPasswordSecure = true
    @State private var isConfirmPasswordSecure = true
    
    enum Field {
        case fullName
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 15) {
                        TextField("Full Name", text: $viewModel.fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .focused($focusedField, equals: .fullName)
                        
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .email)
                        
                        ZStack(alignment: .trailing) {
                            Group {
                                if isPasswordSecure {
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
                                isPasswordSecure.toggle()
                            } label: {
                                Image(systemName: isPasswordSecure ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                        
                        ZStack(alignment: .trailing) {
                            Group {
                                if isConfirmPasswordSecure {
                                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                } else {
                                    TextField("Confirm Password", text: $viewModel.confirmPassword)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.oneTimeCode) // This prevents password suggestions
                            .focused($focusedField, equals: .confirmPassword)
                            
                            Button {
                                isConfirmPasswordSecure.toggle()
                            } label: {
                                Image(systemName: isConfirmPasswordSecure ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                        
                        Button {
                            Task {
                                await viewModel.signUp()
                            }
                        } label: {
                            Text("Sign Up")
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
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .onTapGesture {
                focusedField = nil
            }
        }
    }
}

#Preview {
    SignUpView()
} 