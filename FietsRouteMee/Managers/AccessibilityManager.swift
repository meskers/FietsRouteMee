//
//  AccessibilityManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 18/10/2025.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

@MainActor
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverEnabled = false
    @Published var isReduceMotionEnabled = false
    @Published var isReduceTransparencyEnabled = false
    @Published var isDarkerSystemColorsEnabled = false
    @Published var isButtonShapesEnabled = false
    @Published var isOnOffLabelsEnabled = false
    @Published var isSpeakScreenEnabled = false
    @Published var isSpeakSelectionEnabled = false
    @Published var isSwitchControlEnabled = false
    @Published var isGuidedAccessEnabled = false
    @Published var isAssistiveTouchEnabled = false
    @Published var isVoiceControlEnabled = false
    
    // Custom accessibility settings
    @Published var highContrastMode = false
    @Published var largeTextSize = false
    @Published var voiceNavigationEnabled = true
    @Published var hapticFeedbackEnabled = true
    @Published var audioCuesEnabled = true
    
    private init() {
        setupAccessibilityObservers()
        loadCustomSettings()
    }
    
    // MARK: - Setup
    
    private func setupAccessibilityObservers() {
        // Monitor system accessibility settings
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
            }
        }
        
        // Button shapes notification not available in iOS 18
        // NotificationCenter.default.addObserver(
        //     forName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification,
        //     object: nil,
        //     queue: .main
        // ) { [weak self] _ in
        //     self?.isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled
        // }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.onOffSwitchLabelsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isOnOffLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.speakScreenStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isSpeakScreenEnabled = UIAccessibility.isSpeakScreenEnabled
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.speakSelectionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isSpeakSelectionEnabled = UIAccessibility.isSpeakSelectionEnabled
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.switchControlStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.guidedAccessStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isGuidedAccessEnabled = UIAccessibility.isGuidedAccessEnabled
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.assistiveTouchStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
            }
        }
        
        // Voice Control notification not available in iOS 18
        // NotificationCenter.default.addObserver(
        //     forName: UIAccessibility.voiceControlStatusDidChangeNotification,
        //     object: nil,
        //     queue: .main
        // ) { [weak self] _ in
        //     self?.isVoiceControlEnabled = UIAccessibility.isVoiceControlRunning
        // }
        
        // Initialize current values
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        // isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled // Not available in iOS 18
        isOnOffLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled
        isSpeakScreenEnabled = UIAccessibility.isSpeakScreenEnabled
        isSpeakSelectionEnabled = UIAccessibility.isSpeakSelectionEnabled
        isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
        isGuidedAccessEnabled = UIAccessibility.isGuidedAccessEnabled
        isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
        // isVoiceControlEnabled = UIAccessibility.isVoiceControlRunning // Not available in iOS 18
    }
    
    private func loadCustomSettings() {
        let defaults = UserDefaults.standard
        highContrastMode = defaults.bool(forKey: "accessibility.highContrastMode")
        largeTextSize = defaults.bool(forKey: "accessibility.largeTextSize")
        voiceNavigationEnabled = defaults.bool(forKey: "accessibility.voiceNavigationEnabled")
        hapticFeedbackEnabled = defaults.bool(forKey: "accessibility.hapticFeedbackEnabled")
        audioCuesEnabled = defaults.bool(forKey: "accessibility.audioCuesEnabled")
    }
    
    // MARK: - Custom Settings
    
    func setHighContrastMode(_ enabled: Bool) {
        highContrastMode = enabled
        UserDefaults.standard.set(enabled, forKey: "accessibility.highContrastMode")
    }
    
    func setLargeTextSize(_ enabled: Bool) {
        largeTextSize = enabled
        UserDefaults.standard.set(enabled, forKey: "accessibility.largeTextSize")
    }
    
    func setVoiceNavigationEnabled(_ enabled: Bool) {
        voiceNavigationEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "accessibility.voiceNavigationEnabled")
    }
    
    func setHapticFeedbackEnabled(_ enabled: Bool) {
        hapticFeedbackEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "accessibility.hapticFeedbackEnabled")
    }
    
    func setAudioCuesEnabled(_ enabled: Bool) {
        audioCuesEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "accessibility.audioCuesEnabled")
    }
    
    // MARK: - Accessibility Helpers
    
    func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: priority, argument: message)
    }
    
    func announceLayoutChange() {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
    
    func announceScreenChange() {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    func focusOnElement(_ element: Any) {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
    
    // MARK: - Dynamic Type Support
    
    var preferredContentSizeCategory: ContentSizeCategory {
        if largeTextSize {
            return .large
        } else {
            return .medium
        }
    }
    
    // MARK: - Color Accessibility
    
    func getAccessibleColor(_ color: Color, for context: AccessibilityContext) -> Color {
        if highContrastMode || isDarkerSystemColorsEnabled {
            return getHighContrastColor(color, for: context)
        }
        return color
    }
    
    private func getHighContrastColor(_ color: Color, for context: AccessibilityContext) -> Color {
        switch context {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .accent:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .background:
            return highContrastMode ? .black : .primary
        case .foreground:
            return highContrastMode ? .white : .primary
        }
    }
    
    // MARK: - Motion Accessibility
    
    func getAnimationDuration() -> Double {
        return isReduceMotionEnabled ? 0.0 : 0.3
    }
    
    func getSpringAnimation() -> Animation {
        return isReduceMotionEnabled ? .linear(duration: 0.0) : .spring(response: 0.5, dampingFraction: 0.8)
    }
    
    // MARK: - Audio Accessibility
    
    func playAudioCue(_ cue: AudioCue) {
        guard audioCuesEnabled else { return }
        
        switch cue {
        case .success:
            playSystemSound(1057) // Success sound
        case .error:
            playSystemSound(1053) // Error sound
        case .warning:
            playSystemSound(1054) // Warning sound
        case .navigation:
            playSystemSound(1104) // Navigation sound
        case .button:
            playSystemSound(1104) // Button sound
        }
    }
    
    private func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK: - Haptic Accessibility
    
    func playHapticFeedback(_ type: HapticFeedbackType) {
        guard hapticFeedbackEnabled else { return }
        
        switch type {
        case .light:
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        case .medium:
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        case .heavy:
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        case .success:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        case .selection:
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
    }
}

// MARK: - Supporting Types

enum AccessibilityContext {
    case primary
    case secondary
    case accent
    case success
    case warning
    case error
    case background
    case foreground
}

enum AudioCue {
    case success
    case error
    case warning
    case navigation
    case button
}

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}
