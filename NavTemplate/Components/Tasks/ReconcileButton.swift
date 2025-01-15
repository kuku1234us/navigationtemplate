import SwiftUI
import NavTemplateShared

struct ReconcileButton: View {
    @StateObject private var projectModel = ProjectModel.shared
    @State private var isReconciling = false
    @State private var showReconcileSuccess = false
    @State private var showReconcileError = false
    @State private var errorMessage = ""
    @State private var successValue = 0
    
    var body: some View {
        Button(action: {
            Task {
                isReconciling = true
                do {
                    await projectModel.reconcileProjects()
                    showReconcileSuccess = true
                    successValue = successValue + 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    
                    // Reset success state after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showReconcileSuccess = false
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showReconcileError = true
                }
                isReconciling = false
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
                    options: .speed(1),
                    value: successValue
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