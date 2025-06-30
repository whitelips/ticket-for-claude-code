//
//  FileMonitor.swift
//  ticket-for-cc
//
//  Service for monitoring Claude JSONL files using FSEventStream
//

import Foundation
import os.log

protocol FileMonitorDelegate: AnyObject {
    func fileMonitorDidDetectChange()
}

class FileMonitor {
    private var streams: [FSEventStreamRef] = []
    private var pathsToWatch: [String] = []
    weak var delegate: FileMonitorDelegate?
    private let logger = Logger(subsystem: "com.ticket-for-cc", category: "FileMonitor")
    
    init() {
        updateWatchPaths()
    }
    
    private func updateWatchPaths() {
        pathsToWatch.removeAll()
        
        // Try to get path from security-scoped bookmark first
        if let bookmarkURL = SecurityBookmarkService.shared.getClaudeFolderURL() {
            pathsToWatch.append(bookmarkURL.path)
            logger.info("Using security-scoped path: \(bookmarkURL.path)")
        }
        
        // Also check standard locations
        if let realHome = Self.getRealHomeDirectory() {
            // Check both new (.config/claude) and old (.claude) locations
            let claudePaths = [
                "\(realHome)/.config/claude",
                "\(realHome)/.claude"
            ]
            
            for path in claudePaths {
                if FileManager.default.fileExists(atPath: path) && !pathsToWatch.contains(path) {
                    pathsToWatch.append(path)
                    logger.info("Monitoring path: \(path)")
                }
            }
        }
        
        if pathsToWatch.isEmpty {
            logger.warning("No valid Claude directories found to monitor")
        }
    }
    
    func startMonitoring() {
        guard streams.isEmpty else { return }
        
        // Ensure we have valid paths to watch
        updateWatchPaths()
        guard !pathsToWatch.isEmpty else {
            logger.warning("No valid paths to watch")
            return
        }
        
        // Create a stream for each path to watch
        for path in pathsToWatch {
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
                var hasJSONLChange = false
                
                for path in paths {
                    if path.hasSuffix(".jsonl") || path.contains("/projects/") {
                        hasJSONLChange = true
                        monitor.logger.debug("Detected change in: \(path)")
                        break
                    }
                }
                
                if hasJSONLChange {
                    DispatchQueue.main.async {
                        monitor.delegate?.fileMonitorDidDetectChange()
                    }
                }
            }
            
            let pathsArray = [path] as CFArray
            
            let stream = FSEventStreamCreate(
                kCFAllocatorDefault,
                callback,
                &context,
                pathsArray,
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
                streams.append(stream)
                logger.info("Started monitoring: \(path)")
            }
        }
    }
    
    func stopMonitoring() {
        for stream in streams {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        streams.removeAll()
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
