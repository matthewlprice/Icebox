//
//  LineTester.swift
//  Icebox
//
//  Created by Jake Heiser on 7/17/18.
//

import Foundation
import XCTest

public class LineTester {
    
    private var lines: [String]
    
    public init(content: String) {
        self.lines = content.components(separatedBy: "\n")
    }
    
    public func equals(_ str: String, file: StaticString = #file, line: UInt = #line) {
        guard let first = removeFirst(file: file, line: line) else { return }
        XCTAssertEqual(first, str, file: #file, line: line)
    }
    
    public func matches(_ str: StaticString, file: StaticString = #file, line: UInt = #line) {
        guard let first = removeFirst(file: file, line: line) else { return }
        let regex = try! NSRegularExpression(pattern: str.description, options: [])
        
        let match = regex.firstMatch(in: first, options: [], range: NSRange(location: 0, length: first.utf16.count))
        XCTAssertTrue(match != nil, "`\(first)` should match \(regex.pattern)", file: #file, line: line)
    }
    
    public func empty(file: StaticString = #file, line: UInt = #line) {
        equals("", file: file, line: line)
    }
    
    public func any(file: StaticString = #file, line: UInt = #line) {
        _ = removeFirst(file: file, line: line)
    }
    
    public func equalsInAnyOrder(_ lines: Set<String>, file: StaticString = #file, line: UInt = #line) {
        var lines = lines
        while !lines.isEmpty {
            guard let first = removeFirst(file: file, line: line) else { return }
            if lines.contains(first) {
                lines.remove(first)
            } else {
                XCTFail("Unexpected line: \(first)", file: #file, line: line)
                break
            }
        }
    }
    
    public func done(file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(lines, [], file: #file, line: line)
    }
    
    private func removeFirst(file: StaticString, line: UInt) -> String? {
        if lines.isEmpty {
            XCTFail("No lines left", file: file, line: line)
            return nil
        }
        return lines.removeFirst()
    }
    
}
