//
//  StepProgressView.swift
//  Hireo
//
//  Created by Benedikt Held on 19.08.25.
//

import SwiftUI

struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]
    
    var body: some View {
        VStack(spacing: ThemeManager.Spacing.md) {
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? ThemeManager.Colors.primary : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? ThemeManager.Colors.primary : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            Text(stepTitles[min(currentStep, stepTitles.count - 1)])
                .font(ThemeManager.Fonts.headline)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    StepProgressView(
        currentStep: 1,
        totalSteps: 4,
        stepTitles: ["Personal Info", "Education", "Experience", "Skills"]
    )
}