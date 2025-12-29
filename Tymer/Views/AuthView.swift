//
//  AuthView.swift
//  Tymer
//
//  Created by Claude on 26/12/2025.
//

import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var supabase = SupabaseManager.shared

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var selectedColor: Color = .blue

    @State private var showError = false
    @State private var errorMessage = ""

    private let availableColors: [Color] = [
        .red, .blue, .green, .orange, .purple,
        .pink, .cyan, .yellow, .mint, .indigo, .teal, .brown
    ]

    var body: some View {
        ZStack {
            Color.tymerBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Logo
                    logoSection

                    // Title
                    titleSection

                    // Form
                    formSection

                    // Submit Button
                    submitButton

                    // Toggle Mode
                    toggleModeButton

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 8) {
            Text("Tymer")
                .font(.funnelSemiBold(48))
                .foregroundColor(.tymerWhite)

            Text("Capture ton moment")
                .font(.funnelLight(16))
                .foregroundColor(.tymerGray)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(isSignUp ? "Créer un compte" : "Connexion")
                .font(.funnelSemiBold(28))
                .foregroundColor(.tymerWhite)

            Text(isSignUp ? "Rejoins tes amis sur Tymer" : "Content de te revoir !")
                .font(.funnelLight(15))
                .foregroundColor(.tymerGray)
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 16) {
            if isSignUp {
                // First Name
                CustomTextField(
                    placeholder: "Prénom",
                    text: $firstName,
                    icon: "person.fill"
                )

                // Color Picker
                colorPicker
            }

            // Email
            CustomTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )

            // Password
            CustomTextField(
                placeholder: "Mot de passe",
                text: $password,
                icon: "lock.fill",
                isSecure: true
            )

            if isSignUp {
                // Confirm Password
                CustomTextField(
                    placeholder: "Confirmer le mot de passe",
                    text: $confirmPassword,
                    icon: "lock.fill",
                    isSecure: true
                )
            }
        }
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choisis ta couleur")
                .font(.funnelLight(14))
                .foregroundColor(.tymerGray)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                        )
                        .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedColor = color
                            }
                        }
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task {
                await handleSubmit()
            }
        } label: {
            HStack {
                if supabase.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text(isSignUp ? "Créer mon compte" : "Se connecter")
                        .font(.funnelSemiBold(17))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.tymerWhite)
            .foregroundColor(.tymerBlack)
            .cornerRadius(12)
        }
        .disabled(supabase.isLoading || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.5)
    }

    // MARK: - Toggle Mode Button

    private var toggleModeButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                isSignUp.toggle()
                clearForm()
            }
        } label: {
            HStack(spacing: 4) {
                Text(isSignUp ? "Déjà un compte ?" : "Pas encore de compte ?")
                    .font(.funnelLight(15))
                    .foregroundColor(.tymerGray)

                Text(isSignUp ? "Se connecter" : "S'inscrire")
                    .font(.funnelSemiBold(15))
                    .foregroundColor(.tymerWhite)
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   !firstName.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    // MARK: - Actions

    private func handleSubmit() async {
        do {
            if isSignUp {
                guard password == confirmPassword else {
                    errorMessage = "Les mots de passe ne correspondent pas"
                    showError = true
                    return
                }

                try await supabase.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    avatarColor: selectedColor.colorName
                )
            } else {
                try await supabase.signIn(email: email, password: password)
            }

            // Process any pending invitation after login
            appState.processPendingInviteIfNeeded()

            // Navigate to gate on success
            appState.navigate(to: .gate)

        } catch {
            errorMessage = supabase.errorMessage ?? "Une erreur est survenue"
            showError = true
        }
    }

    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        selectedColor = .blue
    }
}

// MARK: - Custom TextField

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.tymerGray)
                    .frame(width: 20)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
                    .font(.funnelLight(16))
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .font(.funnelLight(16))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color.tymerWhite.opacity(0.1))
        .foregroundColor(.tymerWhite)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tymerWhite.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environment(AppState())
}
