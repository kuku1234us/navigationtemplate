import SwiftUI
import NavTemplateShared

struct ReconcileButton: View {
    @StateObject private var projectModel = ProjectModel.shared
    @State private var isReconciling = false
    @State private var showReconcileSuccess = false
    @State private var showReconcileError = false
    @State private var errorMessage = ""
    @State private var successValue = 0
    @State private var rotationValue = 0
    
    var body: some View {
        Button(action: {
            Task {
                // Start rotation
                isReconciling = true
                rotationValue += 1
                
                do {
                    try await projectModel.reconcileProjects()
                    
                    // Success animation
                    await MainActor.run {
                        showReconcileSuccess = true
                        successValue += 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    
                    // Reset success state after delay
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await MainActor.run {
                        showReconcileSuccess = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showReconcileError = true
                    }
                }
                
                // Stop rotation
                await MainActor.run {
                    isReconciling = false
                }
            }
        }) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(showReconcileSuccess ? .green : Color("MyTertiary"))
                .font(.system(size: 16, weight: showReconcileSuccess ? .bold : .regular))
                .symbolEffect(
                    .bounce,
                    options: .speed(1),
                    value: successValue
                )
                .symbolEffect(
                    .rotate,
                    options: .repeating.speed(1),
                    value: rotationValue
                )
        }
        .disabled(isReconciling)
        .toast(isPresenting: $showReconcileError) {
            Toast(
                type: .error,
                title: "Reconciliation Failed",
                message: errorMessage.isEmpty ? "Failed to reconcile projects" : errorMessage
            )
        }
    }
} 