//
//  RunResult.swift
//  Icebox
//
//  Created by Jake Heiser on 7/17/18.
//

import Foundation

public struct RunResult {
    
    public let exitStatus: Int32
    public let stdoutData: Data
    public let stderrData: Data
    
    public var stdout: String? {
        return String(data: stdoutData, encoding: .utf8)
    }
    
    public var stderr: String? {
        return String(data: stderrData, encoding: .utf8)
    }
    
    init(exitStatus: Int32, stdoutData: Data, stderrData: Data) {
        self.exitStatus = exitStatus
        self.stdoutData = stdoutData
        self.stderrData = stderrData
    }
    
    public func assertStdout(_ test: (LineTester) -> ()) {
        let tester = LineTester(content: stdout ?? "")
        test(tester)
    }
    
    public func assertStderr(_ test: (LineTester) -> ()) {
        let tester = LineTester(content: stderr ?? "")
        test(tester)
    }
    
}
