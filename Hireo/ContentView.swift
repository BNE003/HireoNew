//
//  ContentView.swift
//  Hireo
//
//  Created by Benedikt Held on 14.08.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        Group {
            if dataManager.hasUserProfile() {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(dataManager)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ModernProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text(NSLocalizedString("profile", comment: ""))
                }
            
            ModernApplicationsView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text(NSLocalizedString("applications", comment: ""))
                }
            
            ModernTemplatesView()
                .tabItem {
                    Image(systemName: "doc.badge.plus")
                    Text(NSLocalizedString("templates", comment: ""))
                }
            
            ModernDocumentsView()
                .tabItem {
                    Image(systemName: "doc.on.doc.fill")
                    Text(NSLocalizedString("documents", comment: ""))
                }
            
            ModernSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(NSLocalizedString("settings", comment: ""))
                }
        }
        .tint(ModernTheme.Colors.primarySolid)
    }
}

#Preview {
    ContentView()
}
