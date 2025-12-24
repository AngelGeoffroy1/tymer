//
//  DigestView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct DigestView: View {
    @Environment(AppState.self) private var appState
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Week info
                weekInfoSection
                
                // Photo grid
                photoGrid
                
                Spacer()
                
                // Footer message
                footerSection
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            TymerBackButton {
                appState.navigate(to: .gate)
            }
            
            Spacer()
            
            Text("Mon Digest")
                .font(.tymerSubheadline)
                .foregroundColor(.tymerWhite)
            
            Spacer()
            
            // Spacer pour équilibrer
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Week Info
    private var weekInfoSection: some View {
        VStack(spacing: 8) {
            Text(weekRangeString)
                .font(.funnelLight(14))
                .foregroundColor(.tymerGray)
            
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                Text("\(appState.weeklyDigest.count) moments cette semaine")
                    .font(.funnelLight(14))
            }
            .foregroundColor(.tymerWhite)
        }
        .padding(.vertical, 24)
    }
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        
        return "\(formatter.string(from: weekAgo)) - \(formatter.string(from: today))"
    }
    
    // MARK: - Photo Grid
    private var photoGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(appState.weeklyDigest) { moment in
                MomentThumbnail(moment, size: thumbnailSize)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var thumbnailSize: CGFloat {
        (UIScreen.main.bounds.width - 40 - 16) / 3
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("Ton résumé personnel")
                .font(.tymerCaption)
                .foregroundColor(.tymerGray)
            
            Text("Visible uniquement par toi")
                .font(.funnelLight(12))
                .foregroundColor(.tymerDarkGray)
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    DigestView()
        .environment(AppState())
}
