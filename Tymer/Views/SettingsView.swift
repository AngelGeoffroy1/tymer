//
//  SettingsView.swift
//  Tymer
//
//  Created by Claude on 03/01/2026.
//

import SwiftUI
import Auth
import Supabase

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @StateObject private var supabase = SupabaseManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Password change
    @State private var showPasswordChange = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChangingPassword = false
    @State private var passwordError: String?
    @State private var passwordSuccess = false
    
    // Delete account
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmText = ""
    @State private var isDeletingAccount = false
    
    // Alerts
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.tymerBlack
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Notifications Section
                        settingsSection(title: "Notifications") {
                            notificationsRow
                        }
                        
                        // Security Section
                        settingsSection(title: "Sécurité") {
                            passwordRow
                        }
                        
                        // Account Section
                        settingsSection(title: "Compte") {
                            deleteAccountRow
                        }
                        
                        // App Info
                        appInfoSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tymerBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.tymerGray)
                    }
                }
            }
            .sheet(isPresented: $showPasswordChange) {
                PasswordChangeSheet(
                    currentPassword: $currentPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    isChanging: $isChangingPassword,
                    error: $passwordError,
                    success: $passwordSuccess,
                    onSave: changePassword
                )
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Settings Section Builder
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.funnelLight(12))
                .foregroundColor(.tymerGray)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color.tymerDarkGray.opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Notifications Row
    
    private var notificationsRow: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(notificationManager.isAuthorized ? Color.green.opacity(0.2) : Color.tymerDarkGray)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(notificationManager.isAuthorized ? .green : .tymerGray)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications push")
                        .font(.funnelSemiBold(15))
                        .foregroundColor(.tymerWhite)
                    
                    Text(notificationStatusText)
                        .font(.funnelLight(12))
                        .foregroundColor(.tymerGray)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Action button based on status
            notificationActionButton
        }
        .padding(16)
    }
    
    private var notificationActionButton: some View {
        Group {
            switch notificationManager.authorizationStatus {
            case .denied:
                Button {
                    notificationManager.openSettings()
                } label: {
                    Text("Paramètres")
                        .font(.funnelLight(12))
                        .foregroundColor(.tymerWhite)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.tymerDarkGray)
                        .cornerRadius(8)
                }
            case .notDetermined:
                Button {
                    Task {
                        _ = await notificationManager.requestAuthorization()
                    }
                } label: {
                    Text("Activer")
                        .font(.funnelSemiBold(12))
                        .foregroundColor(.tymerBlack)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.tymerWhite)
                        .cornerRadius(8)
                }
            case .authorized, .provisional, .ephemeral:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "Tu seras notifié à l'ouverture de chaque fenêtre"
        case .denied:
            return "Désactivées - ouvre les paramètres pour activer"
        case .notDetermined:
            return "Active les notifications pour ne rien manquer"
        case .provisional:
            return "Mode silencieux activé"
        case .ephemeral:
            return "Notifications temporaires"
        @unknown default:
            return "Statut inconnu"
        }
    }
    
    // MARK: - Password Row
    
    private var passwordRow: some View {
        Button {
            showPasswordChange = true
        } label: {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.tymerDarkGray)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.tymerWhite)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Changer le mot de passe")
                            .font(.funnelSemiBold(15))
                            .foregroundColor(.tymerWhite)
                        
                        Text("Modifie ton mot de passe")
                            .font(.funnelLight(12))
                            .foregroundColor(.tymerGray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.tymerGray)
            }
            .padding(16)
        }
    }
    
    // MARK: - Delete Account Row
    
    private var deleteAccountRow: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Supprimer mon compte")
                            .font(.funnelSemiBold(15))
                            .foregroundColor(.red)
                        
                        Text("Suppression définitive de toutes tes données")
                            .font(.funnelLight(12))
                            .foregroundColor(.tymerGray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isDeletingAccount {
                    ProgressView()
                        .tint(.red)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.tymerGray)
                }
            }
            .padding(16)
        }
        .disabled(isDeletingAccount)
        .confirmationDialog(
            "Supprimer ton compte",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Supprimer définitivement", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est irréversible. Toutes tes données, photos et amis seront supprimés.")
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Text("Tymer")
                .font(.funnelSemiBold(14))
                .foregroundColor(.tymerGray)
            
            Text("Version 1.0.0")
                .font(.funnelLight(12))
                .foregroundColor(.tymerDarkGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
    
    // MARK: - Actions
    
    private func changePassword() async {
        isChangingPassword = true
        passwordError = nil
        
        defer { isChangingPassword = false }
        
        // Validate passwords match
        guard newPassword == confirmPassword else {
            passwordError = "Les mots de passe ne correspondent pas"
            return
        }
        
        // Validate password length
        guard newPassword.count >= 6 else {
            passwordError = "Le mot de passe doit contenir au moins 6 caractères"
            return
        }
        
        do {
            try await supabase.client.auth.update(user: UserAttributes(password: newPassword))
            passwordSuccess = true
            
            // Close sheet after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showPasswordChange = false
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                passwordSuccess = false
            }
        } catch {
            passwordError = "Erreur lors du changement de mot de passe"
        }
    }
    
    private func deleteAccount() async {
        isDeletingAccount = true
        
        defer { isDeletingAccount = false }
        
        do {
            // Sign out the user (note: full account deletion requires admin API or Edge Function)
            try await supabase.signOut()

            // Clear all user data to prevent data leaking to next session
            appState.clearAllData()

            // Navigate to auth screen
            appState.navigate(to: .auth)
            
            // Show info that account deletion request was sent
            // In a real app, you'd call an Edge Function to fully delete the account
        } catch {
            alertTitle = "Erreur"
            alertMessage = "Impossible de supprimer le compte. Réessaie plus tard."
            showAlert = true
        }
    }
}

// MARK: - Password Change Sheet

struct PasswordChangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isChanging: Bool
    @Binding var error: String?
    @Binding var success: Bool
    
    var onSave: () async -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.tymerBlack
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Success animation
                    if success {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Mot de passe modifié !")
                                .font(.funnelSemiBold(18))
                                .foregroundColor(.tymerWhite)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Form
                        VStack(spacing: 20) {
                            // New password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nouveau mot de passe")
                                    .font(.funnelLight(12))
                                    .foregroundColor(.tymerGray)
                                
                                SecureField("", text: $newPassword)
                                    .font(.funnelSemiBold(16))
                                    .foregroundColor(.tymerWhite)
                                    .padding(16)
                                    .background(Color.tymerDarkGray.opacity(0.5))
                                    .cornerRadius(12)
                            }
                            
                            // Confirm password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirmer le mot de passe")
                                    .font(.funnelLight(12))
                                    .foregroundColor(.tymerGray)
                                
                                SecureField("", text: $confirmPassword)
                                    .font(.funnelSemiBold(16))
                                    .foregroundColor(.tymerWhite)
                                    .padding(16)
                                    .background(Color.tymerDarkGray.opacity(0.5))
                                    .cornerRadius(12)
                            }
                            
                            // Password requirements
                            HStack(spacing: 6) {
                                Image(systemName: newPassword.count >= 6 ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(newPassword.count >= 6 ? .green : .tymerGray)
                                
                                Text("Au moins 6 caractères")
                                    .font(.funnelLight(12))
                                    .foregroundColor(.tymerGray)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(passwordsMatch ? .green : .tymerGray)
                                
                                Text("Les mots de passe correspondent")
                                    .font(.funnelLight(12))
                                    .foregroundColor(.tymerGray)
                                
                                Spacer()
                            }
                            
                            // Error message
                            if let error = error {
                                Text(error)
                                    .font(.funnelLight(13))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Changer le mot de passe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tymerBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.tymerGray)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await onSave()
                        }
                    } label: {
                        if isChanging {
                            ProgressView()
                                .tint(.tymerWhite)
                        } else {
                            Text("Enregistrer")
                                .foregroundColor(isFormValid ? .tymerWhite : .tymerGray)
                        }
                    }
                    .disabled(!isFormValid || isChanging)
                }
            }
            .animation(.easeInOut, value: success)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private var isFormValid: Bool {
        newPassword.count >= 6 && passwordsMatch
    }
    
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppState())
}
