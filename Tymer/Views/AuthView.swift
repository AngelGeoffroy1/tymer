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

    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.tymerBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo fixed at top
                logoSection
                    .padding(.top, 16)
                
                Spacer()
                
                // Centered form content
                VStack(spacing: 32) {
                    // Title
                    titleSection

                    // Form
                    formSection

                    // Submit Button
                    submitButton

                    // Toggle Mode
                    toggleModeButton
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Debug: Reset Onboarding button
                #if DEBUG
                debugSection
                    .padding(.bottom, 20)
                #endif
            }
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Debug Section (only in DEBUG builds)
    #if DEBUG
    private var debugSection: some View {
        Button {
            appState.hasCompletedOnboarding = false
            appState.navigate(to: .onboarding)
        } label: {
            Text("Onboarding")
                .font(.funnelLight(11))
                .foregroundColor(.tymerDarkGray.opacity(0.5))
        }
        .padding(.top, 20)
    }
    #endif

    // MARK: - Logo Section

    private var logoSection: some View {
        Text("Tymer")
            .font(.funnelSemiBold(32))
            .foregroundColor(.tymerWhite)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isSignUp ? "Créer un compte" : "Connexion")
                .font(.funnelSemiBold(28))
                .foregroundColor(.tymerWhite)

            Text(isSignUp ? "Rejoins tes amis sur Tymer" : "Content de te revoir !")
                .font(.funnelLight(15))
                .foregroundColor(.tymerGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    firstName: firstName
                )
            } else {
                try await supabase.signIn(email: email, password: password)
            }

            // CRITICAL: Clear old user data before loading new user's data
            // This prevents data from previous account persisting after login
            appState.clearAllData()

            // Reload app data for the new user
            await appState.loadData()

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
    }
}

// MARK: - Custom TextField with Underline Style

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(isFocused ? .tymerWhite : .tymerGray)
                        .frame(width: 24)
                        .animation(.easeInOut(duration: 0.25), value: isFocused)
                }

                // Text field
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                        .font(.funnelLight(17))
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled()
                        .font(.funnelLight(17))
                        .focused($isFocused)
                }
            }
            .foregroundColor(.tymerWhite)
            .padding(.bottom, 12)
            
            // Animated underline
            ZStack(alignment: .leading) {
                // Background line (always visible, subtle)
                Rectangle()
                    .fill(Color.tymerGray.opacity(0.3))
                    .frame(height: 1)
                
                // Animated foreground line (expands from left on focus)
                Rectangle()
                    .fill(Color.tymerWhite)
                    .frame(width: isFocused ? .infinity : 0, height: 2)
                    .frame(maxWidth: isFocused ? .infinity : 0)
                    .animation(.easeInOut(duration: 0.3), value: isFocused)
            }
            .frame(height: 2)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environment(AppState())
}
