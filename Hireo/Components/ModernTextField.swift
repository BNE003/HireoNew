//
//  ModernTextField.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let isSecure: Bool
    let validation: ValidationRule?
    
    @FocusState private var isFocused: Bool
    @State private var validationMessage: String = ""
    @State private var isValid: Bool = true
    
    enum ValidationRule {
        case email
        case required
        case phone
        case custom((String) -> (isValid: Bool, message: String))
    }
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isSecure: Bool = false,
        validation: ValidationRule? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isSecure = isSecure
        self.validation = validation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernTheme.Spacing.xs) {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                    .fill(ModernTheme.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .frame(height: 56)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isFocused = true
                    }
                    .animation(ModernTheme.Animations.quick, value: isFocused)
                
                // Content
                HStack {
                    VStack(alignment: .leading, spacing: hasContent ? 2 : 8) {
                        // Floating Label
                        if hasContent {
                            Text(title)
                                .font(labelFont)
                                .foregroundColor(labelColor)
                                .animation(ModernTheme.Animations.spring, value: isFocused)
                        }
                        
                        // Input Field Container
                        ZStack(alignment: .leading) {
                            // Placeholder or Label when not focused and empty
                            if !hasContent {
                                Text(title)
                                    .font(ModernTheme.Typography.bodyLarge)
                                    .foregroundColor(ModernTheme.Colors.textSecondary)
                                    .allowsHitTesting(false)
                            }
                            
                            // Actual Input Field
                            Group {
                                if isSecure {
                                    SecureField("", text: $text)
                                } else {
                                    TextField("", text: $text)
                                }
                            }
                            .font(ModernTheme.Typography.bodyLarge)
                            .foregroundColor(ModernTheme.Colors.textPrimary)
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .focused($isFocused)
                            .submitLabel(.next)
                        }
                        .frame(minHeight: 24)
                    }
                    
                    Spacer()
                    
                    // Status Indicator
                    if !isValid && !validationMessage.isEmpty {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(ModernTheme.Colors.error)
                            .font(.title3)
                    } else if isValid && !text.isEmpty && validation != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ModernTheme.Colors.success)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, ModernTheme.Spacing.md)
            }
            
            // Validation Message
            if !validationMessage.isEmpty && !isValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(validationMessage)
                        .font(ModernTheme.Typography.caption)
                }
                .foregroundColor(ModernTheme.Colors.error)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: text) { _, newValue in
            validateInput(newValue)
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                validateInput(text)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasContent: Bool {
        !text.isEmpty || isFocused
    }
    
    private var labelFont: Font {
        hasContent ? ModernTheme.Typography.labelSmall : ModernTheme.Typography.bodyLarge
    }
    
    private var labelColor: Color {
        if !isValid {
            return ModernTheme.Colors.error
        } else if isFocused {
            return ModernTheme.Colors.primarySolid
        } else {
            return ModernTheme.Colors.textSecondary
        }
    }
    
    
    private var borderColor: Color {
        if !isValid {
            return ModernTheme.Colors.error
        } else if isFocused {
            return ModernTheme.Colors.primarySolid
        } else {
            return ModernTheme.Colors.border
        }
    }
    
    private var borderWidth: CGFloat {
        if !isValid || isFocused {
            return 2
        } else {
            return 1
        }
    }
    
    // MARK: - Validation
    
    private func validateInput(_ input: String) {
        guard let validation = validation else {
            isValid = true
            validationMessage = ""
            return
        }
        
        let result: (isValid: Bool, message: String)
        
        switch validation {
        case .required:
            result = input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? (false, "This field is required")
                : (true, "")
            
        case .email:
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            result = emailPredicate.evaluate(with: input)
                ? (true, "")
                : (false, "Please enter a valid email address")
            
        case .phone:
            let phoneRegex = "^[+]?[0-9\\s\\-\\(\\)]{10,}$"
            let phonePredicate = NSPredicate(format:"SELF MATCHES %@", phoneRegex)
            result = phonePredicate.evaluate(with: input)
                ? (true, "")
                : (false, "Please enter a valid phone number")
            
        case .custom(let validator):
            result = validator(input)
        }
        
        withAnimation(ModernTheme.Animations.quick) {
            isValid = result.isValid
            validationMessage = result.message
        }
    }
}

// MARK: - Modern Text Area

struct ModernTextArea: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let minLines: Int
    let maxLines: Int
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String = "",
        minLines: Int = 3,
        maxLines: Int = 8
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.minLines = minLines
        self.maxLines = maxLines
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernTheme.Spacing.xs) {
            // Floating Label
            if hasContent {
                Text(title)
                    .font(ModernTheme.Typography.labelSmall)
                    .foregroundColor(labelColor)
                    .animation(ModernTheme.Animations.spring, value: isFocused)
            }
            
            // Text Area
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                    .fill(ModernTheme.Colors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernTheme.Radius.md)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .frame(minHeight: CGFloat(minLines * 20 + 32))
                
                VStack(alignment: .leading, spacing: 0) {
                    // Placeholder when no content and not focused
                    if !hasContent {
                        HStack {
                            Text(title)
                                .font(ModernTheme.Typography.bodyLarge)
                                .foregroundColor(ModernTheme.Colors.textSecondary)
                                .allowsHitTesting(false)
                            Spacer()
                        }
                        .padding(ModernTheme.Spacing.md)
                    }
                    
                    // The actual text field
                    TextField(hasContent ? placeholder : "", text: $text, axis: .vertical)
                        .font(ModernTheme.Typography.bodyLarge)
                        .foregroundColor(ModernTheme.Colors.textPrimary)
                        .lineLimit(minLines...maxLines)
                        .focused($isFocused)
                        .padding(ModernTheme.Spacing.md)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isFocused = true
                        }
                }
            }
        }
        .animation(ModernTheme.Animations.spring, value: hasContent)
    }
    
    private var hasContent: Bool {
        !text.isEmpty || isFocused
    }
    
    private var labelColor: Color {
        isFocused ? ModernTheme.Colors.primarySolid : ModernTheme.Colors.textSecondary
    }
    
    private var borderColor: Color {
        isFocused ? ModernTheme.Colors.primarySolid : ModernTheme.Colors.border
    }
    
    private var borderWidth: CGFloat {
        isFocused ? 2 : 1
    }
}

#Preview {
    VStack(spacing: 24) {
        ModernTextField(
            title: "Institution",
            text: .constant(""),
            placeholder: "University of Example",
            validation: .required
        )
        
        ModernTextField(
            title: "Degree",
            text: .constant("Bachelor of Science"),
            placeholder: "Bachelor of Science",
            validation: .required
        )
        
        ModernTextField(
            title: "Field of Study",
            text: .constant(""),
            placeholder: "Computer Science"
        )
        
        ModernTextField(
            title: "Grade/GPA",
            text: .constant("3.8/4.0 or First Class"),
            placeholder: "3.8/4.0 or First Class"
        )
        
        ModernTextArea(
            title: "Relevant coursework, achievements, or activities",
            text: .constant(""),
            placeholder: "Relevant coursework, thesis topic, awards, activities...",
            minLines: 3,
            maxLines: 6
        )
    }
    .padding()
    .background(ModernTheme.Colors.surface)
}