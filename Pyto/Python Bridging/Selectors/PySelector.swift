//
//  PySelector.swift
//  Pyto
//
//  Created by Adrian Labbé on 1/20/19.
//  Copyright © 2019 Adrian Labbé. All rights reserved.
//

import Foundation

/// A helper for making selectors without classes.
@objc class PySelector: NSObject {
    
    /// Makes a selector from any object.
    ///
    /// - Parameters:
    ///     - block: Block callable by the selector.
    ///
    /// - Returns: A Selector for calling `item` or `nil`.
    static func makeSelector(_ item: Any) -> Selector? {
        if let block = item as? ((Any?) -> Void) {
            return makeSelector(block)
        } else if let block = item as? (() -> Void) {
            return makeSelector(block)
        } else {
            PyOutputHelper.print("Invalid block!\n", script: nil)
            return nil
        }
    }
    
    /// Makes a selector.
    ///
    /// - Parameters:
    ///     - block: Block callable by the selector.
    ///
    /// - Returns: A Selector for calling `block`
    @objc static func makeSelector(_ block: @escaping () -> Void) -> Selector {
        let item = block as Any
        
        if let selectorWithoutParameters = item as? (() -> Void) {
            return Selector(selectorWithoutParameters)
        } else if let selectorWithParameters = item as? ((Any?) -> Void) {
            return Selector(selectorWithParameters)
        } else {
            return Selector(block)
        }
    }
}
