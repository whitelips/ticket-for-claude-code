import SwiftUI
import AppKit

struct PermissionRequestView: View {
    @State private var isRequestingAccess = false
    @Binding var isPresented: Bool
    var onAccessGranted: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Permission Required")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This app needs access to your Claude configuration folder to monitor usage.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Label("The app will read Claude usage data", systemImage: "doc.text")
                Label("Located in ~/.claude/ or ~/.config/claude/", systemImage: "folder")
                Label("Read-only access", systemImage: "lock")
            }
            .font(.callout)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.automatic)
                
                Button("Grant Access") {
                    isRequestingAccess = true
                    SecurityBookmarkService.shared.requestClaudeFolderAccess { success in
                        isRequestingAccess = false
                        if success {
                            onAccessGranted()
                            isPresented = false
                        } else {
                            // Show error alert
                            showAccessDeniedAlert()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequestingAccess)
            }
        }
        .padding(30)
        .frame(width: 450)
    }
    
    private func showAccessDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Access Denied"
        alert.informativeText = "Without access to the Claude configuration folder, this app cannot monitor your usage. Please select the ~/.config/claude folder when prompted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// Helper view to check and request permissions
struct PermissionCheckView<Content: View>: View {
    @State private var hasPermission = false
    @State private var showPermissionRequest = false
    @State private var isCheckingPermission = true
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if isCheckingPermission {
                ProgressView("Checking permissions...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear(perform: checkPermission)
            } else if hasPermission {
                content
            } else {
                VStack {
                    Spacer()
                    PermissionRequestView(
                        isPresented: .constant(true),
                        onAccessGranted: {
                            hasPermission = true
                        }
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func checkPermission() {
        // Check if we have bookmark access
        hasPermission = SecurityBookmarkService.shared.hasClaudeFolderAccess()
        isCheckingPermission = false
        
        if !hasPermission {
            showPermissionRequest = true
        }
    }
}
