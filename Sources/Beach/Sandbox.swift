//
//  Sandbox.swift
//  Beach
//
//  Created by Jake Heiser on 6/8/18.
//

import Foundation

class Beach<T: Sandbox> {
    
    typealias Prep = (_ process: Process) -> ()
    
    private var preps: [Prep] = []
    
    init(executable: String) {
        let path = "/.build/debug/" + executable
        configure { (process) in
            process.launchPath = path
        }
    }
    
    func run(arguments: [String], in box: T? = nil, prep: Prep) {
        let boxPath = "/tmp/Beach"
        if FileManager.default.fileExists(atPath: boxPath) {
            try! FileManager.default.removeItem(atPath: boxPath)
        }
        
        if let box = box {
            try! FileManager.default.copyItem(atPath: T.directory + box.rawValue, toPath: boxPath)
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
        preps.forEach { $0(process) }
        
        process.launch()
        process.waitUntilExit()
        
        let stdout = out.fileHandleForReading.readDataToEndOfFile()
        let stderr = err.fileHandleForReading.readDataToEndOfFile()
    }
    
    func configure(_ prep: @escaping Prep) {
        preps.append(prep)
    }
    
}

protocol Sandbox: RawRepresentable where Self.RawValue == String {
    static var directory: String { get }
}

extension Sandbox {
    static var directory: String {
        return "Tests/Sandboxes/"
    }
}

enum MySanbox: String, Sandbox {
    case lib
    case exec
    case fail
}

func run() {
    let beach = Beach<MySanbox>(executable: "ice")
    beach.configure { (process) in
        var env = ProcessInfo.processInfo.environment
        env["ICE_GLOBAL_ROOT"] = "global"
        process.environment = env
    }
}
//myBeach.run(in: .Lib)
