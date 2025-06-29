import Foundation

protocol FileMonitorDelegate: AnyObject {
    func fileMonitorDidDetectChange()
}

class FileMonitor {
    private var stream: FSEventStreamRef?
    private var pathToWatch: String?
    weak var delegate: FileMonitorDelegate?
    
    init() {
        updateWatchPath()
    }
    
    private func updateWatchPath() {
        // Try to get path from security-scoped bookmark first
        if let bookmarkURL = SecurityBookmarkService.shared.getClaudeFolderURL() {
            pathToWatch = bookmarkURL.path
            print("FileMonitor using security-scoped path: \(bookmarkURL.path)")
        } else {
            // Fallback to attempting direct access (won't work in sandbox without permission)
            if let realHome = Self.getRealHomeDirectory() {
                // Watch the .claude directory to catch changes in any subdirectory
                // This will catch changes in both:
                // - ~/.claude/projects/PROJECT-NAME/*.jsonl
                // - ~/.config/claude/*.jsonl
                pathToWatch = "\(realHome)/.claude"
                
                // If .claude doesn't exist, try .config/claude
                if !FileManager.default.fileExists(atPath: pathToWatch!) {
                    pathToWatch = "\(realHome)/.config/claude"
                }
            } else {
                pathToWatch = "\(NSHomeDirectory())/.claude"
            }
            print("FileMonitor attempting direct path (may fail due to sandbox): \(self.pathToWatch ?? "none")")
        }
    }
    
    func startMonitoring() {
        guard stream == nil else { return }
        
        // Ensure we have a valid path to watch
        updateWatchPath()
        guard let watchPath = pathToWatch else {
            print("FileMonitor: No valid path to watch")
            return
        }
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: FSEventStreamCallback = { _, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds in
            guard let info = clientCallBackInfo else { return }
            let monitor = Unmanaged<FileMonitor>.fromOpaque(info).takeUnretainedValue()
            
            // Check if any of the changed files are JSONL files
            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
            for path in paths {
                if path.hasSuffix(".jsonl") {
                    DispatchQueue.main.async {
                        monitor.delegate?.fileMonitorDidDetectChange()
                    }
                    break
                }
            }
        }
        
        let pathsToWatch = [watchPath] as CFArray
        
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0, // latency in seconds
            FSEventStreamCreateFlags(
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagWatchRoot |
                kFSEventStreamCreateFlagUseCFTypes
            )
        )
        
        if let stream = stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }
    
    func stopMonitoring() {
        guard let stream = stream else { return }
        
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }
    
    deinit {
        stopMonitoring()
    }
}

extension FileMonitor {
    
    static func getRealHomeDirectory() -> String? {
        let pw = getpwuid(getuid())
        if let homeDir = pw?.pointee.pw_dir {
            return String(cString: homeDir)
        }
        return nil
    }

    // 또는 더 간단한 방법
    static func getRealHomePath() -> String {
        return String(cString: getpwuid(getuid()).pointee.pw_dir)
    }
    
    
}
