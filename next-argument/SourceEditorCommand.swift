//
//  SourceEditorCommand.swift
//  next-argument
//
//  Created by Ricky Joudrey on 9/12/16.
//  Copyright © 2016 com. All rights reserved.
//

import Foundation
import XcodeKit

extension String {
    func rangeOfString(matchingPattern pattern: String) -> Range<String.Index>? {
        let matcher = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = matcher.matches(in: self, options: [], range: NSRange(location: 0, length: characters.count))
        if let range = matches.first?.range {
            let lowerBound = index(startIndex, offsetBy: range.location)
            let upperBound = index(lowerBound, offsetBy: range.length)
            return Range(uncheckedBounds: (lower: lowerBound, upper: upperBound))
        }
        return nil
    }
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        if let cursor = invocation.buffer.selections.firstObject as? XCSourceTextRange {
            let allLines = Array(invocation.buffer.lines).map { $0 as! String }
            let line = allLines[cursor.start.line]
            if let colonLoc = nextColon(in: line, startColumn: cursor.start.column) {
                moveCursor(cursor, toColumn: colonLoc)
            }
            else {
                for lineIndex in allLines.indices.suffix(from: cursor.start.line) {
                    let line = allLines[lineIndex]
                    if let colonLoc = nextColon(in: line) {
                        moveCursor(cursor, toColumn: colonLoc, line: lineIndex)
                        break
                    }
                }
            }
        }
        completionHandler(nil)
    }
    
    func moveCursor(_ cursor: XCSourceTextRange, toColumn column: Int, line: Int? = nil) {
        cursor.start.column = column
        cursor.end.column = column
        if let line = line {
            cursor.start.line = line
            cursor.end.line = line
        }
    }
    
    func nextColon(in line: String, startColumn: Int = 0) -> Int? {
        let rem = String(line.characters.suffix(from: line.characters.index(line.characters.startIndex, offsetBy: startColumn)))
        if let matchEnd = rem.rangeOfString(matchingPattern: ": [^ ]*?")?.upperBound {
            let remOffset = rem.distance(from: rem.startIndex, to: matchEnd)
            let lineOffset = startColumn + remOffset
            return lineOffset
        }
        return nil
    }
    
}
