//
//  MarkdownSplitView.swift
//  Pyto
//
//  Created by Adrian Labbé on 1/18/19.
//  Copyright © 2019 Adrian Labbé. All rights reserved.
//

import UIKit
import SplitKit

/// A Split view controller with Markdown text and preview.
class MarkdownSplitViewController: SplitViewController {
    
    /// The editor.
    var editor: PlainTextEditorViewController! {
        didSet {
            firstChild = editor
        }
    }
    
    /// The previewer.
    var previewer: MarkdownPreviewController! {
        didSet {
            secondChild = previewer
        }
    }
    
    /// Creates and returns a new instance.
    ///
    /// - Parameters:
    ///     - fullScreen: If set to `true`, only the markdown preview will be shown.
    init(fullScreen: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        if fullScreen {
            ratio = 0
        }
    }
    
    // MARK: - Split view controller
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let firstChild = self.firstChild, let secondChild = self.secondChild else {
            return
        }
        
        firstChild.viewWillTransition(to: firstChild.view.frame.size, with: ViewControllerTransitionCoordinator())
        secondChild.viewWillTransition(to: firstChild.view.frame.size, with: ViewControllerTransitionCoordinator())
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        
        viewDidLayoutSubviews()
        
        arrangement = .horizontal
    }
}
