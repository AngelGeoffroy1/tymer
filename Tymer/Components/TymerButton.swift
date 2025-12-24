//
//  TymerButton.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

// MARK: - Tymer Button Component
struct TymerButton: View {
    let title: String
    let style: TymerButtonType
    let action: () -> Void
    
    enum TymerButtonType {
        case primary
        case secondary
        case ghost
    }
    
    init(_ title: String, style: TymerButtonType = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        switch style {
        case .primary:
            Button(action: action) {
                Text(title)
            }
            .buttonStyle(TymerPrimaryButtonStyle())
            
        case .secondary:
            Button(action: action) {
                Text(title)
            }
            .buttonStyle(TymerSecondaryButtonStyle())
            
        case .ghost:
            Button(action: action) {
                Text(title)
            }
            .buttonStyle(TymerGhostButtonStyle())
        }
    }
}

// MARK: - Icon Button
struct TymerIconButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void
    
    init(_ systemName: String, size: CGFloat = 24, action: @escaping () -> Void) {
        self.systemName = systemName
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .light))
                .foregroundColor(.tymerWhite)
                .frame(width: 44, height: 44)
        }
    }
}

// MARK: - Back Button
struct TymerBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("Retour")
                    .font(.funnelLight(16))
            }
            .foregroundColor(.tymerWhite)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TymerButton("Entrer", style: .primary) {}
        TymerButton("Capturer", style: .secondary) {}
        TymerButton("Plus tard", style: .ghost) {}
        
        HStack(spacing: 20) {
            TymerIconButton("camera.fill") {}
            TymerIconButton("person.2.fill") {}
            TymerIconButton("calendar") {}
        }
        
        TymerBackButton {}
    }
    .padding()
    .tymerBackground()
}
