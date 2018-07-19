//
//  Loggger.swift
//  Icebox
//
//  Created by Jake Heiser on 7/19/18.
//

struct Logger {
    
    struct Colors {
        private static let escape = "\u{001B}["
        static let none   = escape + "0m"
        static let red    = escape + "0;31m"
        static let blue = escape + "0;34m"
        
        private init() {}
    }
    
    static func info(_ str: String) {
        print("\(Colors.blue)Icebox: \(Colors.none)\(str)")
    }
    
    static func error(_ str: String) {
        print()
        print("\(Colors.red)Icebox: \(Colors.none)\(str)")
        print()
    }
    
    private init() {}
    
}
