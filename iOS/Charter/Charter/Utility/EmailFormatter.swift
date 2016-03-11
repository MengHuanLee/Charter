//
//  EmailFormatter.swift
//  Charter
//
//  Created by Matthew Palmer on 25/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

class EmailFormatter {
    private lazy var squareBracketAtStartRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "^\\[.*?\\]", options: .CaseInsensitive)
    }()
    
    private lazy var withinParenthesesRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "\\((.*)\\)", options: .CaseInsensitive)
    }()
    
    private lazy var sourceDateFormatter: NSDateFormatter = {
        let df = NSDateFormatter()
        df.dateFormat = "ccc, dd MMM yyyy HH:mm:ss Z"
        df.timeZone = NSTimeZone(abbreviation: "GMT")
        return df
    }()
    
    private lazy var destinationDateFormatter: NSDateFormatter = {
        let df = NSDateFormatter()
        df.dateFormat = "d MMM"
        return df
    }()
    
    private lazy var footerBoilerPlateRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "_______________________________________________.*?$", options: NSRegularExpressionOptions.DotMatchesLineSeparators)
    }()
    
    func formatContent(content: String) -> String {
        let noFooter = footerBoilerPlateRegex.stringByReplacingMatchesInString(content, options: [], range: NSMakeRange(0, content.characters.count), withTemplate: "")
        return noFooter
    }
    
    func formatSubject(subject: String) -> String {
        let noSquareBrackets = squareBracketAtStartRegex.stringByReplacingMatchesInString(subject, options: [], range: NSMakeRange(0, subject.characters.count), withTemplate: "")
        return noSquareBrackets.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    private lazy var squareBracketForLabelRegex: NSRegularExpression = {
        // ^(\[[^\]]*\])+
        return try! NSRegularExpression(pattern: "^(\\[[^\\]]*\\]\\s*)+", options: [])
    }()
    
    func labelsInSubject(string: String) -> [String] {
        let allLabelsStringMatch = squareBracketForLabelRegex.matchesInString(string, options: [], range: NSMakeRange(0, string.characters.count))
        guard let first = allLabelsStringMatch.first else {
            return []
        }
        
        return (string as NSString).substringWithRange(first.range)
            .componentsSeparatedByString("]")
            .map {
                $0.stringByReplacingOccurrencesOfString("[", withString: "")
                    .stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
            }.filter { $0 != "" && $0 != "]" }
    }
    
    func subjectByRemovingLabels(string: String) -> String {
        let allLabelsStringMatch = squareBracketForLabelRegex.matchesInString(string, options: [], range: NSMakeRange(0, string.characters.count))
        guard let first = allLabelsStringMatch.first else {
            return string
        }
        
        return (string as NSString).stringByReplacingCharactersInRange(first.range, withString: "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    func formatName(name: String) -> String {
        let firstMatch = withinParenthesesRegex.firstMatchInString(name, options: [], range: NSMakeRange(0, name.characters.count))
        let range = firstMatch?.rangeAtIndex(1) ?? NSMakeRange(0, name.characters.count)
        let withinParens = (name as NSString).substringWithRange(range)
        
        // The server sometimes sends us ?utf-8? junk, and there's nothing we can do.
        let noJunk: String
        if withinParens.hasPrefix("=?utf-8?") {
            noJunk = ""
        } else {
            noJunk = withinParens
        }
        
        return noJunk
    }
    
    func dateStringToDate(date: String) -> NSDate? {
        return sourceDateFormatter.dateFromString(date)
    }
    
    func formatDate(date: NSDate) -> String {
        return destinationDateFormatter.stringFromDate(date)
    }
}
