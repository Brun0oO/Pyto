//
//  ShortenFilePaths.swift
//  Pyto
//
//  Created by Adrian Labbé on 5/14/19.
//  Copyright © 2019 Adrian Labbé. All rights reserved.
//

import Foundation

/// Shortens file paths accesable from the app.
///
/// - Parameters:
///     - str: The string containing paths.
///
/// - Returns: The given string with shortened file paths.
func ShortenFilePaths(in str: String) -> String {
    
    var text = str
    
    text = str.replacingOccurrences(of: DocumentBrowserViewController.localContainerURL.path, with: "Documents")
    text = text.replacingOccurrences(of: "/privateDocuments", with: "Documents")
    if let iCloudDrive = DocumentBrowserViewController.iCloudContainerURL {
        text = text.replacingOccurrences(of: iCloudDrive.path, with: "iCloud")
    }
    
    text = text.replacingOccurrences(of: Bundle.main.bundlePath, with: "Pyto.app")
    text = text.replacingOccurrences(of: "/privatePyto.app", with: "Pyto.app")
    
    return text
}
