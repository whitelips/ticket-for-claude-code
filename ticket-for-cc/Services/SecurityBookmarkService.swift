import Foundation
import AppKit

class SecurityBookmarkService {
    static let shared = SecurityBookmarkService()
    
    private let bookmarkKey = "claudeFolderBookmark"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // Check if we have access to the Claude folder
    func hasClaudeFolderAccess() -> Bool {
        if let bookmarkData = userDefaults.data(forKey: bookmarkKey) {
            return resolveBookmark(bookmarkData) != nil
        }
        return false
    }
    
    // Get the Claude folder URL from bookmark
    func getClaudeFolderURL() -> URL? {
        guard let bookmarkData = userDefaults.data(forKey: bookmarkKey),
              let url = resolveBookmark(bookmarkData) else {
            return nil
        }
        return url
    }
    
    // Request access to Claude folder from user
    func requestClaudeFolderAccess(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let openPanel = NSOpenPanel()
            openPanel.title = "Grant Access to Claude Configuration"
            openPanel.message = "Please select the .claude folder to monitor your Claude usage. This is typically located in your home directory."
            openPanel.prompt = "Grant Access"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = false
            openPanel.allowsMultipleSelection = false
            
            // Set default directory to user's home to show .claude directory
            if let realHome = self.getRealHomeDirectory() {
                let claudeURL = URL(fileURLWithPath: "\(realHome)/.claude")
                if FileManager.default.fileExists(atPath: claudeURL.path) {
                    openPanel.directoryURL = URL(fileURLWithPath: realHome)
                }
            }
            
            openPanel.begin { response in
                if response == .OK, let url = openPanel.url {
                    // Create security-scoped bookmark
                    do {
                        let bookmarkData = try url.bookmarkData(
                            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        
                        // Save bookmark to UserDefaults
                        self.userDefaults.set(bookmarkData, forKey: self.bookmarkKey)
                        completion(true)
                    } catch {
                        print("Failed to create bookmark: \(error)")
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }
    
    // Resolve bookmark and start accessing security-scoped resource
    private func resolveBookmark(_ bookmarkData: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                // Bookmark is stale, need to request access again
                userDefaults.removeObject(forKey: bookmarkKey)
                return nil
            }
            
            // Start accessing security-scoped resource
            if url.startAccessingSecurityScopedResource() {
                return url
            }
            
        } catch {
            print("Failed to resolve bookmark: \(error)")
            userDefaults.removeObject(forKey: bookmarkKey)
        }
        
        return nil
    }
    
    // Stop accessing security-scoped resource (call when done)
    func stopAccessingClaudeFolder() {
        if let url = getClaudeFolderURL() {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    // Helper function to get real home directory
    private func getRealHomeDirectory() -> String? {
        let pw = getpwuid(getuid())
        if let homeDir = pw?.pointee.pw_dir {
            return String(cString: homeDir)
        }
        return nil
    }
}
