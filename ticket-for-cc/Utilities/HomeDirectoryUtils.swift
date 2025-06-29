import Foundation

// Helper function to get real home directory in sandboxed apps
// This uses getpwuid() to bypass sandboxing limitations
func getRealHomeDirectory() -> String? {
    let pw = getpwuid(getuid())
    if let homeDir = pw?.pointee.pw_dir {
        return String(cString: homeDir)
    }
    return nil
}