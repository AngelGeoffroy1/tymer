//
//  OnboardingView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//  Redesigned: Time Awareness Onboarding
//

import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    // Page 0: Le Piège - Time Counter
                    TimeTrappedPage()
                        .tag(0)
                    
                    // Page 1: Le Prix - What you could have done
                    TimeLostPage()
                        .tag(1)
                    
                    // Page 2: L'Addiction - Infinite scroll
                    AddictionPage()
                        .tag(2)
                    
                    // Page 3: La Solution - Tymer concept
                    SolutionPage()
                        .tag(3)
                    
                    // Page 4: Le Choix - CTA
                    ChoicePage(onComplete: onComplete)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: currentPage)
                
                // Progress dots & navigation
                bottomNavigation
            }
        }
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        VStack(spacing: 24) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.tymerWhite : Color.tymerDarkGray)
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            
            // Navigation buttons
            if currentPage < totalPages - 1 {
                HStack(spacing: 16) {
                    // Skip button
                    Button("Passer") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentPage = totalPages - 1
                        }
                    }
                    .font(.funnelLight(14))
                    .foregroundColor(.tymerGray)
                    
                    Spacer()
                    
                    // Continue button
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Continuer")
                                .font(.funnelSemiBold(16))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.tymerBlack)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                        .background(Color.tymerWhite)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 32)
        .padding(.bottom, 16)
    }
}

// MARK: - Page 1: Time Trapped
struct TimeTrappedPage: View {
    @State private var displayedMinutes: Int = 0
    @State private var isAnimating = false
    @State private var showSubtitle = false
    
    // Target: average daily social media usage (147 minutes)
    private let targetMinutes = 147
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Time counter - clean and impactful
            ZStack {
                // Subtle glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 30)
                    .opacity(isAnimating ? 0.8 : 0.3)
                
                // Time counter
                VStack(spacing: 8) {
                    Text("\(displayedMinutes)")
                        .font(.funnelSemiBold(96))
                        .foregroundColor(.tymerWhite)
                        .contentTransition(.numericText())
                    
                    Text("minutes / jour")
                        .font(.funnelLight(16))
                        .foregroundColor(.tymerGray)
                }
            }
            .frame(height: 280)
            
            Spacer()
                .frame(height: 40)
            
            // Text content
            VStack(spacing: 16) {
                Text("Le temps s'envole")
                    .font(.funnelSemiBold(28))
                    .foregroundColor(.tymerWhite)
                
                Text("En moyenne, tu passes **2h27** par jour\nsur les réseaux sociaux.")
                    .font(.funnelLight(16))
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showSubtitle ? 1 : 0)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            startCounterAnimation()
        }
    }
    
    private func startCounterAnimation() {
        // Reset
        displayedMinutes = 0
        isAnimating = false
        showSubtitle = false
        
        // Start clock distortion
        withAnimation(.easeInOut(duration: 1.5)) {
            isAnimating = true
        }
        
        // Animate counter with accelerating speed
        let totalDuration: Double = 2.5
        let steps = 50
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            // Ease-out: starts fast, slows down
            let easedProgress = 1 - pow(1 - progress, 3)
            let value = Int(Double(targetMinutes) * easedProgress)
            let delay = totalDuration * progress
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayedMinutes = value
                }
            }
        }
        
        // Show subtitle after counter finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.3) {
            withAnimation(.easeIn(duration: 0.5)) {
                showSubtitle = true
            }
        }
    }
}

// MARK: - Page 2: Time Lost
struct TimeLostPage: View {
    @State private var showItems = false
    @State private var currentHighlight = 0
    
    private let lostActivities: [(icon: String, activity: String, time: String)] = [
        ("book.fill", "Lire 15 livres", "par an"),
        ("figure.walk", "Faire 300 balades", "par an"),
        ("person.2.fill", "889 heures avec tes proches", "par an"),
        ("brain.head.profile", "Apprendre une langue", "en 6 mois")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            // Title at top - more impactful
            VStack(spacing: 12) {
                Text("Ce temps perdu, c'est...")
                    .font(.funnelSemiBold(28))
                    .foregroundColor(.tymerWhite)
                
                Text("889 heures par an que tu aurais pu\nutiliser autrement")
                    .font(.funnelLight(15))
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 50)
            
            // Activities list
            VStack(spacing: 16) {
                ForEach(Array(lostActivities.enumerated()), id: \.offset) { index, activity in
                    ActivityRow(
                        icon: activity.icon,
                        activity: activity.activity,
                        time: activity.time,
                        isHighlighted: currentHighlight == index,
                        delay: Double(index) * 0.15
                    )
                    .opacity(showItems ? 1 : 0)
                    .offset(x: showItems ? 0 : -30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.15), value: showItems)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            showItems = false
            currentHighlight = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showItems = true
            }
            
            // Cycle through highlights
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentHighlight = (currentHighlight + 1) % lostActivities.count
                }
            }
        }
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let activity: String
    let time: String
    let isHighlighted: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isHighlighted ? Color.tymerWhite.opacity(0.15) : Color.tymerDarkGray.opacity(0.5))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isHighlighted ? .tymerWhite : .tymerGray)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(activity)
                    .font(.funnelSemiBold(15))
                    .foregroundColor(isHighlighted ? .tymerWhite : .tymerGray)
                
                Text(time)
                    .font(.funnelLight(12))
                    .foregroundColor(.tymerDarkGray)
            }
            
            Spacer()
            
            // Checkmark when highlighted
            if isHighlighted {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tymerWhite)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHighlighted ? Color.tymerWhite.opacity(0.05) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
    }
}

// MARK: - Page 3: Addiction (Infinite Scroll)
struct AddictionPage: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolling = true
    @State private var scrollSpeed: Double = 1.0
    @State private var showMessage = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Title at top
            VStack(spacing: 12) {
                Text("Le scroll infini")
                    .font(.funnelSemiBold(28))
                    .foregroundColor(.tymerWhite)
                
                Text("Conçu pour te garder captif")
                    .font(.funnelLight(15))
                    .foregroundColor(.tymerGray)
            }
            
            Spacer()
                .frame(height: 40)
            
            // Infinite scroll visualization
            ZStack {
                // Phone frame
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.tymerDarkGray.opacity(0.3))
                    .frame(width: 200, height: 380)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.tymerWhite.opacity(0.2), lineWidth: 2)
                    )
                
                // Scrolling content
                ScrollingContent(offset: scrollOffset, speed: scrollSpeed)
                    .frame(width: 180, height: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        // Gradient fade at top and bottom
                        VStack {
                            LinearGradient(
                                colors: [Color.tymerBlack.opacity(0.8), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 40)
                            
                            Spacer()
                            
                            LinearGradient(
                                colors: [.clear, Color.tymerBlack.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 40)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                // "Break free" overlay
                if showMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.tymerWhite)
                        
                        Text("Et si on arrêtait ?")
                            .font(.funnelSemiBold(18))
                            .foregroundColor(.tymerWhite)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            startScrollAnimation()
        }
    }
    
    private func startScrollAnimation() {
        scrollOffset = 0
        isScrolling = true
        scrollSpeed = 1.0
        showMessage = false
        
        // Continuous scrolling animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            scrollOffset = -2000
        }
        
        // After 3 seconds, start slowing down
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 1.5)) {
                scrollSpeed = 0.1
            }
        }
        
        // Show message
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showMessage = true
            }
        }
    }
}

// MARK: - Scrolling Content for Phone
struct ScrollingContent: View {
    let offset: CGFloat
    let speed: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<20) { i in
                // Mock post
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.tymerDarkGray)
                        .frame(width: 30, height: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.tymerDarkGray.opacity(0.7))
                            .frame(width: CGFloat.random(in: 60...100), height: 10)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.tymerDarkGray.opacity(0.4))
                            .frame(width: CGFloat.random(in: 40...80), height: 8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                // Mock image
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: Double(i) * 0.1, saturation: 0.3, brightness: 0.3),
                                Color(hue: Double(i) * 0.1 + 0.1, saturation: 0.3, brightness: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .padding(.horizontal, 12)
            }
        }
        .offset(y: offset * speed)
    }
}

// MARK: - Page 4: The Solution
struct SolutionPage: View {
    @State private var showWindows = false
    @State private var activeWindow = 0
    @State private var showCheckmarks = false
    
    private let features: [(icon: String, text: String)] = [
        ("clock.badge.checkmark", "2 fenêtres par jour seulement"),
        ("person.2.fill", "15-25 vrais amis max"),
        ("camera.fill", "1 seul moment par jour"),
        ("hand.raised.fill", "Zéro scroll infini")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Tymer logo
            Text("Tymer")
                .font(.funnelSemiBold(42))
                .foregroundColor(.tymerWhite)
            
            Spacer()
                .frame(height: 12)
            
            Text("Reprends le contrôle")
                .font(.funnelLight(16))
                .foregroundColor(.tymerGray)
            
            Spacer()
                .frame(height: 50)
            
            // Windows visualization
            WindowsVisualization(showWindows: showWindows, activeWindow: activeWindow)
                .frame(height: 120)
            
            Spacer()
                .frame(height: 50)
            
            // Features list
            VStack(spacing: 20) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureRow(
                        icon: feature.icon,
                        text: feature.text,
                        showCheck: showCheckmarks,
                        delay: Double(index) * 0.2
                    )
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            showWindows = false
            showCheckmarks = false
            activeWindow = 0
            
            // Animate windows appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showWindows = true
                }
            }
            
            // Animate active window
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    activeWindow = (activeWindow + 1) % 2
                }
            }
            
            // Show checkmarks
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCheckmarks = true
                }
            }
        }
    }
}

// MARK: - Windows Visualization
struct WindowsVisualization: View {
    let showWindows: Bool
    let activeWindow: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Timeline
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Base line
                    Rectangle()
                        .fill(Color.tymerDarkGray)
                        .frame(height: 4)
                        .offset(y: 50)
                    
                    // Morning window
                    WindowBlock(
                        label: "Matin",
                        time: "7h-8h",
                        isActive: activeWindow == 0,
                        position: 0.15
                    )
                    .opacity(showWindows ? 1 : 0)
                    .offset(x: showWindows ? geo.size.width * 0.15 : -50)
                    
                    // Evening window
                    WindowBlock(
                        label: "Soir",
                        time: "19h-21h",
                        isActive: activeWindow == 1,
                        position: 0.65
                    )
                    .opacity(showWindows ? 1 : 0)
                    .offset(x: showWindows ? geo.size.width * 0.65 : geo.size.width + 50)
                    
                    // Time labels
                    HStack {
                        Text("0h")
                            .font(.funnelLight(10))
                            .foregroundColor(.tymerDarkGray)
                        
                        Spacer()
                        
                        Text("12h")
                            .font(.funnelLight(10))
                            .foregroundColor(.tymerDarkGray)
                        
                        Spacer()
                        
                        Text("24h")
                            .font(.funnelLight(10))
                            .foregroundColor(.tymerDarkGray)
                    }
                    .offset(y: 70)
                    .padding(.horizontal, 8)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Window Block
struct WindowBlock: View {
    let label: String
    let time: String
    let isActive: Bool
    let position: CGFloat
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.funnelSemiBold(13))
                .foregroundColor(isActive ? .tymerWhite : .tymerGray)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.green.opacity(0.8) : Color.tymerDarkGray)
                .frame(width: 60, height: 30)
                .overlay(
                    Text(time)
                        .font(.funnelLight(10))
                        .foregroundColor(isActive ? .white : .tymerGray)
                )
            
            // Connector to timeline
            Rectangle()
                .fill(isActive ? Color.green : Color.tymerDarkGray)
                .frame(width: 2, height: 12)
        }
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    let showCheck: Bool
    let delay: Double
    
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Check icon
            ZStack {
                Circle()
                    .fill(appeared ? Color.green.opacity(0.2) : Color.tymerDarkGray.opacity(0.5))
                    .frame(width: 40, height: 40)
                
                Image(systemName: appeared ? "checkmark" : icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(appeared ? .green : .tymerGray)
            }
            
            Text(text)
                .font(.funnelLight(15))
                .foregroundColor(.tymerWhite)
            
            Spacer()
        }
        .opacity(appeared ? 1 : 0.5)
        .offset(x: appeared ? 0 : -20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appeared = showCheck
                }
            }
        }
        .onChange(of: showCheck) { _, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appeared = newValue
                }
            }
        }
    }
}

// MARK: - Page 5: The Choice
struct ChoicePage: View {
    @State private var showContent = false
    @State private var sandFlowing = false
    var onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated Hourglass
            AnimatedHourglass(isAnimating: sandFlowing)
                .frame(width: 120, height: 180)
            
            Spacer()
                .frame(height: 60)
            
            // Text content
            VStack(spacing: 16) {
                Text("Prêt à reprendre\nton temps ?")
                    .font(.funnelSemiBold(28))
                    .foregroundColor(.tymerWhite)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                Text("Moins de scroll, plus de moments vrais.\nTymer t'aide à vivre ta vie.")
                    .font(.funnelLight(15))
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 50)
            
            // CTA Button
            Button {
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                onComplete()
            } label: {
                HStack(spacing: 12) {
                    Text("Commencer")
                        .font(.funnelSemiBold(18))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.tymerBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.tymerWhite)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            showContent = false
            sandFlowing = false
            
            // Start hourglass animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                sandFlowing = true
            }
            
            // Show content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Animated Hourglass
struct AnimatedHourglass: View {
    let isAnimating: Bool
    
    @State private var sandOffset: CGFloat = 0
    @State private var topSandHeight: CGFloat = 50
    @State private var bottomSandHeight: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Subtle glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.tymerWhite.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)
            
            // Hourglass shape
            ZStack {
                // Glass outline
                HourglassShape()
                    .stroke(Color.tymerWhite.opacity(0.6), lineWidth: 2)
                    .frame(width: 80, height: 140)
                
                // Top sand
                HourglassTopSand(fillAmount: topSandHeight / 50)
                    .fill(
                        LinearGradient(
                            colors: [Color.tymerWhite.opacity(0.9), Color.tymerWhite.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 140)
                
                // Falling sand stream
                if isAnimating && topSandHeight > 5 {
                    Rectangle()
                        .fill(Color.tymerWhite.opacity(0.8))
                        .frame(width: 2, height: 30)
                        .offset(y: sandOffset)
                        .opacity(topSandHeight > 5 ? 1 : 0)
                }
                
                // Bottom sand
                HourglassBottomSand(fillAmount: bottomSandHeight / 50)
                    .fill(
                        LinearGradient(
                            colors: [Color.tymerWhite.opacity(0.6), Color.tymerWhite.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 140)
            }
            .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            if isAnimating {
                startSandAnimation()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startSandAnimation()
            }
        }
    }
    
    private func startSandAnimation() {
        // Reset
        topSandHeight = 50
        bottomSandHeight = 0
        sandOffset = 0
        
        // Animate sand flowing
        withAnimation(.linear(duration: 4)) {
            topSandHeight = 5
            bottomSandHeight = 45
        }
        
        // Animate sand stream
        withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
            sandOffset = 10
        }
        
        // After sand flows, flip and repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                rotation += 180
            }
            
            // Restart animation after flip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                topSandHeight = 50
                bottomSandHeight = 0
                startSandAnimation()
            }
        }
    }
}

// MARK: - Hourglass Shapes
struct HourglassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h / 2
        let neckWidth: CGFloat = 8
        
        // Top half
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w/2 + neckWidth/2, y: midY),
            control: CGPoint(x: w, y: midY - 10)
        )
        path.addLine(to: CGPoint(x: w/2 - neckWidth/2, y: midY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: 0),
            control: CGPoint(x: 0, y: midY - 10)
        )
        
        // Bottom half
        path.move(to: CGPoint(x: w/2 - neckWidth/2, y: midY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h),
            control: CGPoint(x: 0, y: midY + 10)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w/2 + neckWidth/2, y: midY),
            control: CGPoint(x: w, y: midY + 10)
        )
        
        return path
    }
}

struct HourglassTopSand: Shape {
    var fillAmount: CGFloat // 0 to 1
    
    var animatableData: CGFloat {
        get { fillAmount }
        set { fillAmount = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h / 2
        let sandHeight = (midY - 15) * fillAmount
        
        guard fillAmount > 0.05 else { return path }
        
        // Sand fills from top
        let topY = midY - 15 - sandHeight
        let topWidth = w * (1 - (1 - fillAmount) * 0.7)
        
        path.move(to: CGPoint(x: (w - topWidth) / 2, y: topY))
        path.addLine(to: CGPoint(x: (w + topWidth) / 2, y: topY))
        path.addQuadCurve(
            to: CGPoint(x: w/2 + 3, y: midY - 5),
            control: CGPoint(x: (w + topWidth) / 2, y: midY - 20)
        )
        path.addLine(to: CGPoint(x: w/2 - 3, y: midY - 5))
        path.addQuadCurve(
            to: CGPoint(x: (w - topWidth) / 2, y: topY),
            control: CGPoint(x: (w - topWidth) / 2, y: midY - 20)
        )
        
        return path
    }
}

struct HourglassBottomSand: Shape {
    var fillAmount: CGFloat // 0 to 1
    
    var animatableData: CGFloat {
        get { fillAmount }
        set { fillAmount = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h / 2
        let sandHeight = (midY - 15) * fillAmount
        
        guard fillAmount > 0.05 else { return path }
        
        // Sand accumulates at bottom
        let bottomY = h - 5
        let sandTopY = bottomY - sandHeight
        let bottomWidth = w * 0.9
        let topWidth = w * (0.3 + fillAmount * 0.5)
        
        path.move(to: CGPoint(x: (w - bottomWidth) / 2, y: bottomY))
        path.addLine(to: CGPoint(x: (w + bottomWidth) / 2, y: bottomY))
        path.addQuadCurve(
            to: CGPoint(x: (w + topWidth) / 2, y: sandTopY),
            control: CGPoint(x: (w + bottomWidth) / 2, y: sandTopY + sandHeight * 0.3)
        )
        
        // Top curve of sand pile
        path.addQuadCurve(
            to: CGPoint(x: (w - topWidth) / 2, y: sandTopY),
            control: CGPoint(x: w / 2, y: sandTopY - sandHeight * 0.15)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: (w - bottomWidth) / 2, y: bottomY),
            control: CGPoint(x: (w - bottomWidth) / 2, y: sandTopY + sandHeight * 0.3)
        )
        
        return path
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(onComplete: {})
}
