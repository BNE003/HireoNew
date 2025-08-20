//
//  ModernViews.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

// MARK: - Modern Applications View
struct ModernApplicationsView: View {
    var body: some View {
        NavigationStack {
            Text("Modern Applications View - Coming Soon")
                .font(ModernTheme.Typography.headingMedium)
                .navigationTitle("Applications")
        }
    }
}

// MARK: - Modern Templates View
struct ModernTemplatesView: View {
    var body: some View {
        TemplatesView()
    }
}

// MARK: - Modern Documents View
struct ModernDocumentsView: View {
    var body: some View {
        NavigationStack {
            Text("Modern Documents View - Coming Soon")
                .font(ModernTheme.Typography.headingMedium)
                .navigationTitle("Documents")
        }
    }
}

// MARK: - Modern Settings View
struct ModernSettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Modern Settings View - Coming Soon")
                .font(ModernTheme.Typography.headingMedium)
                .navigationTitle("Settings")
        }
    }
}

// MARK: - Modern Profile Edit View
struct ModernProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Modern Profile Edit - Coming Soon")
                .font(ModernTheme.Typography.headingMedium)
                .navigationTitle("Edit Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

