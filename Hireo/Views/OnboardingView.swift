//
//  OnboardingView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var dataManager: DataManager
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode: String = Locale.preferredLanguages.first?.hasPrefix("de") == true ? "de" : "en"
    @State private var currentStep: OnboardingStep = .welcome
    @State private var profile = UserProfile()
    @State private var animateContent = false

    var body: some View {
        NavigationStack {
            ZStack {
                onboardingBackground

                VStack(spacing: 16) {
                    progressHeader

                    ScrollView(showsIndicators: false) {
                        stepContent
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                            .padding(.bottom, 24)
                    }

                    footerButtons
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                animateContent = false
                withAnimation(.easeOut(duration: 0.35)) {
                    animateContent = true
                }
            }
            .onChange(of: currentStep) { _, _ in
                animateContent = false
                withAnimation(.easeOut(duration: 0.35)) {
                    animateContent = true
                }
            }
        }
    }

    private var onboardingBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    OnboardingPalette.surface,
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(OnboardingPalette.accentSoft.opacity(0.6))
                .frame(width: 300, height: 300)
                .offset(x: 140, y: -330)
                .blur(radius: 4)

            Circle()
                .fill(OnboardingPalette.slateSoft.opacity(0.35))
                .frame(width: 230, height: 230)
                .offset(x: -170, y: 330)
                .blur(radius: 8)
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text(localized("Schritt \(currentStep.rawValue + 1) von \(OnboardingStep.allCases.count)", "Step \(currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)"))
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundColor(OnboardingPalette.muted)

                Spacer()

                Text(currentStep.groupTitle(isGerman: isGerman))
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundColor(OnboardingPalette.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.82))
                    )
            }

            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step.rawValue <= currentStep.rawValue ? OnboardingPalette.accent : OnboardingPalette.line)
                        .frame(height: 5)
                        .animation(.easeInOut(duration: 0.25), value: currentStep)
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            switch currentStep {
            case .welcome:
                welcomeStep
            case .language:
                languageStep
            case .name:
                nameStep
            case .templates:
                templatesStep
            case .kickoff:
                kickoffStep
            case .location:
                locationStep
            case .role:
                roleStep
            case .contact:
                contactStep
            case .summary:
                summaryStep
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 14)
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("1")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(OnboardingPalette.line, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                Text(localized("Willkommen bei Hireo", "Welcome to Hireo"))
                    .font(.custom("AvenirNext-Bold", size: 34))
                    .foregroundColor(OnboardingPalette.ink)

                Text(localized("Baue deinen Lebenslauf in wenigen Minuten. Modern, klar und professionell.", "Build your resume in minutes. Modern, clear and professional."))
                    .font(.custom("AvenirNext-Regular", size: 18))
                    .foregroundColor(OnboardingPalette.muted)
            }
        }
    }

    private var languageStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(localized("Welche Sprache möchtest du nutzen?", "Which language do you want to use?"))
                .font(.custom("AvenirNext-DemiBold", size: 30))
                .foregroundColor(OnboardingPalette.ink)

            Text(localized("Du kannst das später jederzeit ändern.", "You can change this anytime later."))
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(OnboardingPalette.muted)

            HStack(spacing: 12) {
                languageCard(code: "de", label: "Deutsch")
                languageCard(code: "en", label: "English")
            }
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(localized("Wie dürfen wir dich nennen?", "What should we call you?"))
                .font(.custom("AvenirNext-DemiBold", size: 30))
                .foregroundColor(OnboardingPalette.ink)

            Text(localized("Dein Name erscheint als Header auf deinen Dokumenten.", "Your name will appear as the header on your documents."))
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(OnboardingPalette.muted)

            OnboardingInputField(
                title: localized("Vorname", "First name"),
                text: $profile.personalInfo.firstName,
                prompt: localized("z. B. Anna", "e.g. Anna"),
                keyboardType: .default,
                autocapitalization: .words
            )

            OnboardingInputField(
                title: localized("Nachname", "Last name"),
                text: $profile.personalInfo.lastName,
                prompt: localized("z. B. Schmidt", "e.g. Smith"),
                keyboardType: .default,
                autocapitalization: .words
            )
        }
    }

    private var templatesStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image("2")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 240)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .shadow(color: OnboardingPalette.shadow, radius: 18, y: 10)
                )

            Text(localized("Es warten viele moderne Templates auf dich", "You get access to many modern templates"))
                .font(.custom("AvenirNext-DemiBold", size: 28))
                .foregroundColor(OnboardingPalette.ink)

            templateBadgeRow
        }
    }

    private var kickoffStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localized("Lass uns loslegen", "Let's get started"))
                .font(.custom("AvenirNext-Bold", size: 34))
                .foregroundColor(OnboardingPalette.ink)

            Text(localized("Wir erstellen jetzt gemeinsam deinen Lebenslauf. Schritt für Schritt.", "Now we build your resume together. Step by step."))
                .font(.custom("AvenirNext-Regular", size: 18))
                .foregroundColor(OnboardingPalette.muted)

            onboardingCard(
                icon: "doc.text.fill",
                title: localized("Nur ein paar kurze Fragen", "Just a few short questions"),
                subtitle: localized("Danach ist dein Profil direkt startklar.", "After this, your profile is ready to go.")
            )
        }
    }

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(localized("\(displayName), wo wohnst du denn?", "\(displayName), where do you live?"))
                .font(.custom("AvenirNext-DemiBold", size: 30))
                .foregroundColor(OnboardingPalette.ink)

            OnboardingInputField(
                title: localized("Stadt", "City"),
                text: $profile.personalInfo.address.city,
                prompt: localized("z. B. München", "e.g. Berlin"),
                keyboardType: .default,
                autocapitalization: .words
            )

            OnboardingInputField(
                title: localized("Land", "Country"),
                text: $profile.personalInfo.address.country,
                prompt: localized("z. B. Deutschland", "e.g. Germany"),
                keyboardType: .default,
                autocapitalization: .words
            )

            OnboardingInputField(
                title: localized("Straße (optional)", "Street (optional)"),
                text: $profile.personalInfo.address.street,
                prompt: localized("Straße und Hausnummer", "Street and house number"),
                keyboardType: .default,
                autocapitalization: .words
            )

            OnboardingInputField(
                title: localized("PLZ (optional)", "Postal code (optional)"),
                text: $profile.personalInfo.address.postalCode,
                prompt: localized("z. B. 80331", "e.g. 10001"),
                keyboardType: .numbersAndPunctuation,
                autocapitalization: .none
            )
        }
    }

    private var roleStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(localized("Welche Rolle passt zu dir, \(displayName)?", "Which role fits you best, \(displayName)?"))
                .font(.custom("AvenirNext-DemiBold", size: 30))
                .foregroundColor(OnboardingPalette.ink)

            OnboardingInputField(
                title: localized("Berufsbezeichnung", "Job title"),
                text: $profile.personalInfo.title,
                prompt: localized("z. B. Produktdesigner:in", "e.g. Product Designer"),
                keyboardType: .default,
                autocapitalization: .words
            )

            OnboardingInputField(
                title: localized("Kurzprofil (optional)", "Short summary (optional)"),
                text: $profile.personalInfo.summary,
                prompt: localized("Schreibe 2-3 Sätze über dich", "Write 2-3 sentences about yourself"),
                keyboardType: .default,
                autocapitalization: .sentences,
                axis: .vertical
            )
        }
    }

    private var contactStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(localized("Wie kann man dich erreichen?", "How can people contact you?"))
                .font(.custom("AvenirNext-DemiBold", size: 30))
                .foregroundColor(OnboardingPalette.ink)

            OnboardingInputField(
                title: localized("E-Mail", "Email"),
                text: $profile.personalInfo.email,
                prompt: "name@example.com",
                keyboardType: .emailAddress,
                autocapitalization: .none
            )

            OnboardingInputField(
                title: localized("Telefon (optional)", "Phone (optional)"),
                text: $profile.personalInfo.phone,
                prompt: localized("+49 ...", "+1 ..."),
                keyboardType: .phonePad,
                autocapitalization: .none
            )
        }
    }

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localized("Perfekt, \(displayName)", "Perfect, \(displayName)"))
                .font(.custom("AvenirNext-Bold", size: 34))
                .foregroundColor(OnboardingPalette.ink)

            Text(localized("Dein Profil ist bereit. Jetzt kannst du direkt mit dem ersten Lebenslauf starten.", "Your profile is ready. You can now start your first resume right away."))
                .font(.custom("AvenirNext-Regular", size: 18))
                .foregroundColor(OnboardingPalette.muted)

            VStack(alignment: .leading, spacing: 10) {
                summaryRow(title: localized("Name", "Name"), value: fullName)
                summaryRow(title: localized("Ort", "Location"), value: locationLine)
                summaryRow(title: localized("Rolle", "Role"), value: profile.personalInfo.title)
                summaryRow(title: localized("E-Mail", "Email"), value: profile.personalInfo.email)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: OnboardingPalette.shadow, radius: 14, y: 8)
            )
        }
    }

    private var footerButtons: some View {
        HStack(spacing: 12) {
            if currentStep != .welcome {
                Button(action: previousStep) {
                    Text(localized("Zurück", "Back"))
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundColor(OnboardingPalette.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(OnboardingPalette.line, lineWidth: 1)
                                )
                        )
                }
            }

            Button(action: nextStep) {
                HStack(spacing: 8) {
                    Text(nextButtonTitle)
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                    Image(systemName: currentStep == .summary ? "checkmark" : "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(canProceed ? OnboardingPalette.accent : OnboardingPalette.line)
                        .shadow(color: canProceed ? OnboardingPalette.accent.opacity(0.35) : .clear, radius: 12, y: 7)
                )
            }
            .disabled(!canProceed)
        }
    }

    private func languageCard(code: String, label: String) -> some View {
        let isSelected = selectedLanguageCode == code

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedLanguageCode = code
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.custom("AvenirNext-DemiBold", size: 18))
                Text(code.uppercased())
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .opacity(0.8)
            }
            .foregroundColor(isSelected ? .white : OnboardingPalette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? OnboardingPalette.accent : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? OnboardingPalette.accent : OnboardingPalette.line, lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? OnboardingPalette.accent.opacity(0.25) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var templateBadgeRow: some View {
        HStack(spacing: 10) {
            templateBadge(localized("Modern", "Modern"))
            templateBadge(localized("Minimal", "Minimal"))
            templateBadge(localized("Kreativ", "Creative"))
        }
    }

    private func templateBadge(_ label: String) -> some View {
        Text(label)
            .font(.custom("AvenirNext-DemiBold", size: 13))
            .foregroundColor(OnboardingPalette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(OnboardingPalette.accentSoft)
            )
    }

    private func onboardingCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(OnboardingPalette.accentSoft)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .foregroundColor(OnboardingPalette.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundColor(OnboardingPalette.ink)
                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(OnboardingPalette.muted)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .shadow(color: OnboardingPalette.shadow, radius: 14, y: 8)
        )
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 14))
                .foregroundColor(OnboardingPalette.muted)
                .frame(width: 80, alignment: .leading)

            Text(value.isEmpty ? "-" : value)
                .font(.custom("AvenirNext-DemiBold", size: 15))
                .foregroundColor(OnboardingPalette.ink)

            Spacer()
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case .name:
            return !profile.personalInfo.firstName.trimmed.isEmpty && !profile.personalInfo.lastName.trimmed.isEmpty
        case .location:
            return !profile.personalInfo.address.city.trimmed.isEmpty && !profile.personalInfo.address.country.trimmed.isEmpty
        case .contact:
            return !profile.personalInfo.email.trimmed.isEmpty
        default:
            return true
        }
    }

    private var nextButtonTitle: String {
        if currentStep == .summary {
            return localized("Profil erstellen", "Create profile")
        }

        if currentStep == .kickoff {
            return localized("Daten starten", "Start details")
        }

        return localized("Weiter", "Continue")
    }

    private var isGerman: Bool {
        selectedLanguageCode == "de"
    }

    private var displayName: String {
        let firstName = profile.personalInfo.firstName.trimmed
        return firstName.isEmpty ? localized("Hey", "Hey") : firstName
    }

    private var fullName: String {
        "\(profile.personalInfo.firstName.trimmed) \(profile.personalInfo.lastName.trimmed)".trimmed
    }

    private var locationLine: String {
        "\(profile.personalInfo.address.city.trimmed), \(profile.personalInfo.address.country.trimmed)"
            .trimmingCharacters(in: CharacterSet(charactersIn: ", "))
    }

    private func localized(_ german: String, _ english: String) -> String {
        isGerman ? german : english
    }

    private func nextStep() {
        if currentStep == .summary {
            saveProfile()
            return
        }

        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.33, dampingFraction: 0.88)) {
            currentStep = next
        }
    }

    private func previousStep() {
        guard let previous = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.33, dampingFraction: 0.88)) {
            currentStep = previous
        }
    }

    private func saveProfile() {
        profile.personalInfo.firstName = profile.personalInfo.firstName.trimmed
        profile.personalInfo.lastName = profile.personalInfo.lastName.trimmed
        profile.personalInfo.email = profile.personalInfo.email.trimmed
        profile.personalInfo.address.city = profile.personalInfo.address.city.trimmed
        profile.personalInfo.address.country = profile.personalInfo.address.country.trimmed
        profile.lastUpdated = Date()
        dataManager.saveUserProfile(profile)
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case language
    case name
    case templates
    case kickoff
    case location
    case role
    case contact
    case summary

    func groupTitle(isGerman: Bool) -> String {
        switch self {
        case .welcome, .language, .name, .templates, .kickoff:
            return isGerman ? "Onboarding" : "Onboarding"
        case .location, .role, .contact, .summary:
            return isGerman ? "Profil" : "Profile"
        }
    }
}

private enum OnboardingPalette {
    static let accent = Color(red: 0.972, green: 0.435, blue: 0.373)
    static let accentSoft = Color(red: 1.0, green: 0.89, blue: 0.86)
    static let ink = Color(red: 0.15, green: 0.20, blue: 0.25)
    static let muted = Color(red: 0.39, green: 0.45, blue: 0.50)
    static let slateSoft = Color(red: 0.28, green: 0.36, blue: 0.41)
    static let surface = Color(red: 0.965, green: 0.968, blue: 0.972)
    static let line = Color(red: 0.86, green: 0.88, blue: 0.90)
    static let shadow = Color.black.opacity(0.08)
}

private struct OnboardingInputField: View {
    let title: String
    @Binding var text: String
    let prompt: String
    let keyboardType: UIKeyboardType
    let autocapitalization: UITextAutocapitalizationType
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 14))
                .foregroundColor(OnboardingPalette.muted)

            TextField(prompt, text: $text, axis: axis)
                .font(.custom("AvenirNext-Medium", size: 17))
                .foregroundColor(OnboardingPalette.ink)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(true)
                .autocapitalization(autocapitalization)
                .lineLimit(axis == .vertical ? 3...6 : 1...1)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(OnboardingPalette.line, lineWidth: 1)
                        )
                )
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DataManager.shared)
}
