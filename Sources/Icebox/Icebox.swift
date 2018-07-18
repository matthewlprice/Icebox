//
//  Icebox.swift
//  Icebox
//
//  Created by Jake Heiser on 6/8/18.
//

import Dispatch
import Foundation
import PathKit
import XCTest

public protocol IceboxConfig {
    associatedtype Templates: RawRepresentable where Templates.RawValue == String
    
    static var templateLocation: Path { get }
    static var executable: String { get }
    static var cleanUp: Bool { get }
    static var printLocation: Bool { get }
    
    static func configure(process: Process)
}

public extension IceboxConfig {
    static var templateLocation: Path { return Path("Tests") + "Templates" }
    static var cleanUp: Bool { return false }
    static var printLocation: Bool { return true  }
    
    static func configure(process: Process) {}
}

public class Icebox<Config: IceboxConfig> {
    
    public typealias ProcessConfiguration = (Process) -> ()
    
    private let launchPath: String
    private let boxPath: Path
    private var currentProcess: Process?
    
    public init(template: Config.Templates?, file: StaticString = #file, function: StaticString = #function) {
        let fileComps = Path(file.description).components
        
        let folder: Path
        if let index = fileComps.index(of: "Tests") {
            folder = Path(components: fileComps.prefix(upTo: index))
        } else {
            folder = Path.current
        }
        
        let file = Path(file.description).lastComponentWithoutExtension
        
        if Config.executable.hasPrefix(Path.separator) {
            self.launchPath = Config.executable
        } else {
            self.launchPath = (folder + ".build" + "debug" + Config.executable).absolute().string
        }
        
        let notAllowed = CharacterSet.alphanumerics.inverted
        let trimmedExec = Config.executable.trimmingCharacters(in: notAllowed).replacingOccurrences(of: "/", with: "_")
        let trimmedFunc = function.description.trimmingCharacters(in: notAllowed)
        
        self.boxPath = Path("/tmp") + "icebox" + trimmedExec + file + trimmedFunc
        
        if Config.printLocation {
            print("\(Colors.blue)Icebox: \(Colors.none)running in \(boxPath)")
        }
        
        do {
            if boxPath.exists {
                try boxPath.delete()
            }
            
            if let template = template, template.rawValue.lowercased() != "empty" {
                try boxPath.parent().mkpath()
                try (folder + Config.templateLocation + template.rawValue).copy(boxPath)
            } else {
                try boxPath.mkpath()
            }
        } catch let error {
            print()
            print("\(Colors.red)Icebox error: \(Colors.none)failed to set up icebox directory")
            print()
            print(error)
            print()
            exit(1)
        }
    }
    
    // Set up
    
    public func createFile(path: Path, contents: String, file: StaticString = #file, line: UInt = #line) {
        let adjustedPath = adjustPath(path, file: file, line: line)
        if !adjustedPath.parent().exists {
            gracefulTry(try adjustedPath.parent().mkpath())
        }
        gracefulTry(try adjustedPath.write(contents))
    }
    
    public func createDirectory(path: Path, file: StaticString = #file, line: UInt = #line) {
        gracefulTry(try adjustPath(path, file: file, line: line).mkpath())
    }
    
    public func removeItem(_ path: Path, file: StaticString = #file, line: UInt = #line) {
        gracefulTry(try adjustPath(path, file: file, line: line).delete())
    }
    
    public func fileContents(_ path: Path, file: StaticString = #file, line: UInt = #line) -> String? {
        return try? adjustPath(path, file: file, line: line).read()
    }
    
    public func fileContents(_ path: Path, file: StaticString = #file, line: UInt = #line) -> Data? {
        return try? adjustPath(path, file: file, line: line).read()
    }
    
    public func fileExists(_ path: Path, file: StaticString = #file, line: UInt = #line) -> Bool {
        return adjustPath(path, file: file, line: line).exists
    }
    
    // Run
    
    @discardableResult
    public func run(_ arguments: String..., configure: ProcessConfiguration? = nil, timeout: Int? = nil, file: StaticString = #file, line: UInt = #line) -> RunResult {
        return run(arguments: arguments, configure: configure, timeout: timeout, file: file, line: line)
    }
    
    @discardableResult
    public func run(arguments: [String], configure: ProcessConfiguration? = nil, timeout: Int? = nil, file: StaticString = #file, line: UInt = #line) -> RunResult {
        let out = Pipe()
        let err = Pipe()
        
        let process = Process()
        if Config.executable.hasPrefix(Path.separator) {
            process.launchPath = Config.executable
        } else {
            process.launchPath = (Path.current + ".build" + "debug" + Config.executable).absolute().string
        }
        process.arguments = arguments
        process.currentDirectoryPath = boxPath.string
        process.standardOutput = out
        process.standardError = err
        
        Config.configure(process: process)
        configure?(process)
        
        currentProcess = process
        process.launch()
        
        let interruptItem: DispatchWorkItem? = timeout.flatMap { (timeout) in
            let item = DispatchWorkItem {
                XCTFail("Exceeded timeout (\(timeout) seconds), killing process", file: file, line: line)
                process.terminate()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(timeout), execute: item)
            return item
        }
        
        let outCollector = DataCollector(handle: out.fileHandleForReading)
        let errCollector = DataCollector(handle: err.fileHandleForReading)
        
        let stdout = outCollector.read()
        let stderr = errCollector.read()
        process.waitUntilExit()
        interruptItem?.cancel()
        currentProcess = nil
        
        if Config.cleanUp {
            cleanUp()
        }
        
        return RunResult(exitStatus: process.terminationStatus, stdoutData: stdout, stderrData: stderr)
    }
    
    public func interrupt() {
        currentProcess?.interrupt()
    }
    
    // Clean up
    
    public func cleanUp() {
        gracefulTry(try boxPath.delete())
    }
    
    // Helpers
    
    private func adjustPath(_ relative: Path, file: StaticString, line: UInt) -> Path {
        let full = (boxPath + relative).absolute()
        guard full.string.hasPrefix(boxPath.string + Path.separator) else {
            print()
            print("Icebox: attempted to modify file outside of icebox directory")
            print()
            print("Illegal path `\(full)` resulting from \(file):\(line)")
            print()
            exit(1)
        }
        return full
    }
    
    private func gracefulTry(_ block: @autoclosure () throws -> ()) {
        do {
            try block()
        } catch let error {
            print()
            print("\(Colors.red)Icebox error: \(Colors.none)\(error)")
            print()
            exit(1)
        }
    }
    
}

// MARK: - Private

private class DataCollector {
    
    let source: DispatchSourceRead
    
    private var data = Data()
    private let finished = DispatchSemaphore(value: 0)
    
    init(handle: FileHandle) {
        let source = DispatchSource.makeReadSource(fileDescriptor: handle.fileDescriptor)
        self.source = source
        source.setEventHandler {
            let chunk = handle.availableData
            if chunk.isEmpty {
                source.cancel()
                self.finished.signal()
            } else {
                self.data += chunk
            }
        }
        source.resume()
    }
    
    func read() -> Data {
        finished.wait()
        return data
    }
    
}

private struct Colors {
    private static let escape = "\u{001B}["
    static let none   = escape + "0m"
    static let red    = escape + "0;31m"
    static let blue = escape + "0;34m"
}
