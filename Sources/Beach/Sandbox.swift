//
//  Sandbox.swift
//  Beach
//
//  Created by Jake Heiser on 6/8/18.
//

import Dispatch
import Foundation
import XCTest

protocol Beach {
    typealias Configuration = (_ proc: Process) -> ()
    associatedtype Places: RawRepresentable where Places.RawValue == String
    var location: String { get }
    var executable: String { get }
    func configure(process: Process)
}

struct BeachResult {
    let exitStatus: Int32
    let stdoutData: Data
    let stderrData: Data
    
    var stdout: String? {
        return String(data: stdoutData, encoding: .utf8)
    }
    
    var stderr: String? {
        return String(data: stderrData, encoding: .utf8)
    }
    
    init(exitStatus: Int32, stdoutData: Data, stderrData: Data) {
        self.exitStatus = exitStatus
        self.stdoutData = stdoutData
        self.stderrData = stderrData
    }
}

extension Beach {
    
    // Defaults
    
    var location: String {
        return "Tests/Sandboxes"
    }
    
    func configure(process: Process) {}
    
    // Built-ins
    
    func run(arguments: [String], in box: Places? = nil, configure singleConfig: Configuration? = nil, timeout: Int? = nil, file: StaticString = #file, line: UInt = #line) -> BeachResult {
        let boxPath = "/tmp/Beach"
        if FileManager.default.fileExists(atPath: boxPath) {
            try! FileManager.default.removeItem(atPath: boxPath)
        }
        
        if let box = box {
            try! FileManager.default.copyItem(atPath: location + box.rawValue, toPath: boxPath)
        } else {
            try! FileManager.default.createDirectory(atPath: boxPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        let out = Pipe()
        let err = Pipe()
        
        let process = Process()
        process.arguments = arguments
        process.currentDirectoryPath = boxPath
        process.standardOutput = out
        process.standardError = err
        configure(process: process)
        singleConfig?(process)
        
        process.launch()
        
        var interruptItem: DispatchWorkItem? = nil
        if let timeout = timeout {
            let item = DispatchWorkItem {
                XCTFail("Exceeded timeout (\(timeout) seconds), killing process", file: file, line: line)
                process.interrupt()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(timeout), execute: item)
            interruptItem = item
        }
        
        process.waitUntilExit()
        
        interruptItem?.cancel()
        
        let stdout = out.fileHandleForReading.readDataToEndOfFile()
        let stderr = err.fileHandleForReading.readDataToEndOfFile()
        
        return BeachResult(exitStatus: process.terminationStatus, stdoutData: stdout, stderrData: stderr)
    }
    
}

class IceRink: Beach {
    
    enum Places: String {
        case exec
        case lib
    }
    
    let executable = "ice"
    
    func configure(process: Process) {
        var env = ProcessInfo.processInfo.environment
        env["ICE_GLOBAL_ROOT"] = "global"
        process.environment = env
    }
    
}

func run() {
    let rink = IceRink()
    
    let result = rink.run(arguments: [], in: .lib)
    assert(result.exitStatus == 0)
    assert(result.stdout == "hello")
}
