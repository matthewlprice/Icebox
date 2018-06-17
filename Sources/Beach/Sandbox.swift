//
//  Sandbox.swift
//  Beach
//
//  Created by Jake Heiser on 6/8/18.
//

import Dispatch
import Foundation
import XCTest

protocol RunnerConfig {
    associatedtype Sandboxes: RawRepresentable where Sandboxes.RawValue == String
    
    static var sandboxLocation: String { get }
    static var executable: String { get }
    
    static func configure(process: Process)
}

extension RunnerConfig {
    static var sandboxLocation: String { return "Tests/Sandboxes" }
    
    static func configure(process: Process) {}
}

struct RunnerResult {
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

class Runner<Config: RunnerConfig> {
    
    typealias ProcessConfiguration = (Process) -> ()
    
    let boxPath = "/tmp/Beach"
    
    init(sandbox: Config.Sandboxes?) {
        if FileManager.default.fileExists(atPath: boxPath) {
            try! FileManager.default.removeItem(atPath: boxPath)
        }
        
        if let sandbox = sandbox {
            try! FileManager.default.copyItem(atPath: Config.sandboxLocation + "/" + sandbox.rawValue, toPath: boxPath)
        } else {
            try! FileManager.default.createDirectory(atPath: boxPath, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    // Built-ins
    
    func run(arguments: [String], configure: ProcessConfiguration? = nil, timeout: Int? = nil, file: StaticString = #file, line: UInt = #line) -> RunnerResult {
        let out = Pipe()
        let err = Pipe()
        
        let process = Process()
        process.arguments = arguments
        process.currentDirectoryPath = boxPath
        process.standardOutput = out
        process.standardError = err

        Config.configure(process: process)
        configure?(process)
        
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
        
        return RunnerResult(exitStatus: process.terminationStatus, stdoutData: stdout, stderrData: stderr)
    }
    
}

class IceConfig: RunnerConfig {
    
    enum Sandboxes: String {
        case exec
        case lib
    }
    
    static let executable = "ice"
    
    static func configure(process: Process) {
        var env = ProcessInfo.processInfo.environment
        env["ICE_GLOBAL_ROOT"] = "global"
        process.environment = env
    }
    
}

typealias IceRunner = Runner<IceConfig>

func run() {
    let runner = IceRunner(sandbox: .exec)
    
    let result = runner.run(arguments: [])
    assert(result.exitStatus == 0)
    assert(result.stdout == "hello")
}
