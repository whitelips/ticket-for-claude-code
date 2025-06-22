import Foundation

protocol FileMonitorDelegate: AnyObject {
    func fileMonitorDidDetectChange()
}

class FileMonitor {
    private var stream: FSEventStreamRef?
    private let pathToWatch: String
    weak var delegate: FileMonitorDelegate?
    
    init() {
        self.pathToWatch = NSString(string: "~/.config/claude").expandingTildeInPath
    }
    
    func startMonitoring() {
        guard stream == nil else { return }
        
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
        
        let pathsToWatch = [pathToWatch] as CFArray
        
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0, // latency in seconds
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
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