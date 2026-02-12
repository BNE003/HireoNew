//
//  CoverLetterTemplateCustomizationView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI
import PDFKit

private enum CoverLetterGuidedSectionKind: String, CaseIterable, Identifiable {
    case opening
    case experience
    case value
    case closing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .opening:
            return "Opening Statement"
        case .experience:
            return "Professional Experience Overview"
        case .value:
            return "Role Fit and Value"
        case .closing:
            return "Closing Statement"
        }
    }

    var bullets: [String] {
        switch self {
        case .opening:
            return [
                "Mention where you found the job posting.",
                "Express why this position interests you."
            ]
        case .experience:
            return [
                "Summarize years of experience and focus area.",
                "Reference one relevant achievement."
            ]
        case .value:
            return [
                "Connect your skills to the role requirements.",
                "Describe the impact you can bring to the team."
            ]
        case .closing:
            return [
                "Invite the recruiter to continue the conversation.",
                "Close with a respectful and confident tone."
            ]
        }
    }

    var templateText: String {
        switch self {
        case .opening:
            return "I am writing to express my strong interest in the [Position Title] role at [Company Name], which I found via [Job Source]."
        case .experience:
            return "With [X years] of experience in [Domain/Technology], I have built and delivered [Type of Projects] that improved [Relevant Outcome]."
        case .value:
            return "My experience with [Key Skill 1], [Key Skill 2], and [Key Skill 3] aligns well with your needs. I am confident I can contribute to [Team Goal or Product Area] from day one."
        case .closing:
            return "Thank you for considering my application. I would welcome the opportunity to discuss how I can support [Company Name] in this role."
        }
    }
}

private struct CoverLetterGuidedSectionDraft: Identifiable {
    let kind: CoverLetterGuidedSectionKind
    var text: String

    var id: String { kind.id }

    static func defaults() -> [CoverLetterGuidedSectionDraft] {
        CoverLetterGuidedSectionKind.allCases.map { kind in
            CoverLetterGuidedSectionDraft(kind: kind, text: kind.templateText)
        }
    }
}

enum CoverLetterEditorMode {
    case create
    case customize
}

struct CoverLetterTemplateCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    let template: CoverLetterTemplate
    let mode: CoverLetterEditorMode
    @State private var content = CoverLetterContent()
    @State private var selectedColorScheme: ColorScheme = .blue
    @State private var selectedFontFamily: FontFamily = .system
    @State private var sectionDrafts = CoverLetterGuidedSectionDraft.defaults()
    @State private var expandedSections: Set<CoverLetterGuidedSectionKind> = [.opening]

    @State private var isGeneratingPreview = false
    @State private var showingPDFPreview = false
    @State private var generatedPDFData: Data?
    @State private var errorMessage: String?
    @State private var showingError = false

    init(template: CoverLetterTemplate, mode: CoverLetterEditorMode = .customize) {
        self.template = template
        self.mode = mode
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.96, blue: 1.0),
                        Color(red: 0.88, green: 0.91, blue: 0.99),
                        Color(red: 0.82, green: 0.87, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        templateCard
                        appearanceCard
                        if mode == .create {
                            recipientCard
                            composerCard
                            signatureCard
                            generateCard
                        } else {
                            customizeHintCard
                        }

                        if dataManager.userProfile == nil && mode == .create {
                            warningCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(mode == .create ? "Create Cover Letter" : "Customize Cover Letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if mode == .create {
                        Button("Use Suggestions") {
                            fillWithSuggestions(forceOverwrite: false)
                        }
                        .font(.caption)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            setupInitialContent()
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = generatedPDFData {
                PDFPreviewView(pdfData: pdfData, title: "\(template.name) Cover Letter Preview")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private var templateCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(hex: template.colorSchemes.first?.primaryColor ?? "#007AFF"))
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(template.description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .guidedCardStyle()
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            VStack(alignment: .leading, spacing: 8) {
                Text("Color Scheme")
                    .font(.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(template.colorSchemes, id: \.self) { colorScheme in
                        ColorSchemeOption(
                            colorScheme: colorScheme,
                            isSelected: selectedColorScheme == colorScheme
                        ) {
                            selectedColorScheme = colorScheme
                        }
                    }
                }
            }

            Picker("Font Family", selection: $selectedFontFamily) {
                ForEach(template.fontFamilies, id: \.self) { fontFamily in
                    Text(fontFamily.localizedString)
                        .tag(fontFamily)
                }
            }
            .pickerStyle(.segmented)
        }
        .guidedCardStyle()
    }

    private var recipientCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipient")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            TextField("Company Name", text: $content.recipientCompany)
                .textFieldStyle(.roundedBorder)

            TextField("Contact Person (Optional)", text: Binding(
                get: { content.recipientName ?? "" },
                set: { content.recipientName = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)

            TextField("Position (Optional)", text: Binding(
                get: { content.recipientPosition ?? "" },
                set: { content.recipientPosition = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)

            TextField("Dear [Hiring Manager Name],", text: $content.salutation)
                .textFieldStyle(.roundedBorder)
        }
        .guidedCardStyle()
    }

    private var composerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(Color(hex: selectedColorScheme.primaryColor))
                Text("Cover letter text")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(sectionDrafts.count) sections")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Replace the text within [brackets].")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: selectedColorScheme.secondaryColor).opacity(0.16))
                )

            ForEach($sectionDrafts) { $section in
                let kind = section.kind
                DisclosureGroup(isExpanded: expansionBinding(for: kind)) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(kind.bullets, id: \.self) { bullet in
                                Text("• \(bullet)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        GuidedTextEditor(
                            text: $section.text,
                            placeholder: kind.templateText
                        )
                    }
                    .padding(.top, 10)
                } label: {
                    HStack {
                        Text(kind.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .tint(.primary)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.72))
                )
            }
        }
        .guidedCardStyle()
    }

    private var signatureCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signature")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            TextField("Your name", text: $content.signature)
                .textFieldStyle(.roundedBorder)
        }
        .guidedCardStyle()
    }

    private var generateCard: some View {
        Button(action: generateCoverLetter) {
            HStack {
                if isGeneratingPreview {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(isGeneratingPreview ? "Generating..." : "Generate Cover Letter")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(hex: selectedColorScheme.primaryColor))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(isGeneratingPreview || dataManager.userProfile == nil)
        .guidedCardStyle()
    }

    private var warningCard: some View {
        Text("Please complete your profile to customize and generate documents")
            .font(.caption)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .guidedCardStyle()
    }

    private var customizeHintCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Template Customization")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            Text("The guided text input opens when you tap \"Create Cover Letter\" from the template page.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .guidedCardStyle()
    }

    private func expansionBinding(for kind: CoverLetterGuidedSectionKind) -> Binding<Bool> {
        Binding(
            get: { expandedSections.contains(kind) },
            set: { newValue in
                if newValue {
                    expandedSections.insert(kind)
                } else {
                    expandedSections.remove(kind)
                }
            }
        )
    }

    private func setupInitialContent() {
        content.templateId = template.id
        selectedColorScheme = template.colorSchemes.first ?? .blue
        selectedFontFamily = template.fontFamilies.first ?? .system

        if let userProfile = dataManager.userProfile {
            content.signature = "\(userProfile.personalInfo.firstName) \(userProfile.personalInfo.lastName)"
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if mode == .create {
            fillWithSuggestions(forceOverwrite: false)
        }
    }

    private func fillWithSuggestions(forceOverwrite: Bool) {
        if forceOverwrite || content.salutation.isEmpty {
            content.salutation = "Dear [Hiring Manager's Name],"
        }

        if forceOverwrite || content.signature.isEmpty {
            content.signature = profileNameFallback()
        }

        sectionDrafts = sectionDrafts.map { draft in
            var updatedDraft = draft
            if forceOverwrite || updatedDraft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                updatedDraft.text = draft.kind.templateText
            }
            return updatedDraft
        }

        applyGuidedDraftsToContent()
    }

    private func profileNameFallback() -> String {
        guard let userProfile = dataManager.userProfile else {
            return "[Your Name]"
        }

        let firstName = userProfile.personalInfo.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = userProfile.personalInfo.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)

        return fullName.isEmpty ? "[Your Name]" : fullName
    }

    private func text(for kind: CoverLetterGuidedSectionKind) -> String {
        sectionDrafts.first(where: { $0.kind == kind })?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func applyGuidedDraftsToContent() {
        content.templateId = template.id
        content.introduction = text(for: .opening)

        let bodyParts = [
            text(for: .experience),
            text(for: .value)
        ].filter { !$0.isEmpty }
        content.body = bodyParts.joined(separator: "\n\n")

        content.closing = text(for: .closing)
    }

    private func generateCoverLetter() {
        guard let userProfile = dataManager.userProfile else { return }

        applyGuidedDraftsToContent()
        isGeneratingPreview = true

        Task {
            do {
                let pdfDocument = try await PDFGenerationService.shared.generateCoverLetter(
                    userProfile: userProfile,
                    template: template,
                    content: content
                )

                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFGenerationError.renderingFailed("Failed to get PDF data")
                }

                await MainActor.run {
                    self.generatedPDFData = pdfData
                    self.showingPDFPreview = true
                    self.isGeneratingPreview = false

                    var coverLetterDocument = CoverLetterDocument(
                        userProfileId: userProfile.id,
                        templateId: template.id
                    )
                    coverLetterDocument.colorScheme = selectedColorScheme
                    coverLetterDocument.fontFamily = selectedFontFamily
                    coverLetterDocument.content = content

                    let companyName = content.recipientCompany.isEmpty ? "Company" : content.recipientCompany
                    coverLetterDocument.fileName = "CoverLetter_\(companyName)_\(Date().formatted(.dateTime.year().month().day()))"

                    dataManager.saveCoverLetterDocument(coverLetterDocument)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isGeneratingPreview = false
                }
            }
        }
    }
}

private struct GuidedTextEditor: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
                    .padding(.horizontal, 14)
            }

            TextEditor(text: $text)
                .font(.footnote)
                .padding(8)
                .frame(minHeight: 118)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

private extension View {
    func guidedCardStyle() -> some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
            )
    }
}

#Preview {
    let template = CoverLetterTemplate(
        id: "modern_guided_letter",
        name: "Modern Guided",
        description: "Guided cover letter layout with structured writing prompts",
        category: .modern
    )

    CoverLetterTemplateCustomizationView(template: template)
        .environmentObject(DataManager.shared)
}
