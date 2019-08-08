//
//  ConsoleViewController.swift
//  Pyto
//
//  Created by Adrian Labbe on 9/8/18.
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

import UIKit

/// A View controller containing Python script output.
@objc open class ConsoleViewController: UIViewController, UITextViewDelegate {
    
    #if MAIN
    /// The theme the user choosed.
    static var choosenTheme: Theme {
        set {
            
            let themeID: Int
            
            switch newValue {
            case is XcodeLightTheme:
                themeID = -1
            case is DefaultTheme:
                themeID = 0
            case is XcodeDarkTheme:
                themeID = 1
            case is BasicTheme:
                themeID = 2
            case is DuskTheme:
                themeID = 3
            case is LowKeyTheme:
                themeID = 4
            case is MidnightTheme:
                themeID = 5
            case is SunsetTheme:
                themeID = 6
            case is WWDC16Theme:
                themeID = 7
            case is CoolGlowTheme:
                themeID = 8
            case is SolarizedLightTheme:
                themeID = 9
            case is SolarizedDarkTheme:
                themeID = 10
            default:
                themeID = 0
            }
            
            UserDefaults.standard.set(themeID, forKey: "theme")
            UserDefaults.standard.synchronize()
            
            if #available(iOS 13.0, *) {
                for scene in UIApplication.shared.connectedScenes {
                    (scene.delegate as? UIWindowSceneDelegate)?.window??.tintColor = newValue.tintColor
                }
            }
            
            NotificationCenter.default.post(name: ThemeDidChangeNotification, object: newValue)
        }
        
        get {
            switch UserDefaults.standard.integer(forKey: "theme") {
            case -1:
                return XcodeLightTheme()
            case 0:
                return DefaultTheme()
            case 1:
                return XcodeDarkTheme()
            case 2:
                return BasicTheme()
            case 3:
                return DuskTheme()
            case 4:
                return LowKeyTheme()
            case 5:
                return MidnightTheme()
            case 6:
                return SunsetTheme()
            case 7:
                return WWDC16Theme()
            case 8:
                return CoolGlowTheme()
            case 9:
                return SolarizedLightTheme()
            case 10:
                return SolarizedDarkTheme()
            default:
                return DefaultTheme()
            }
        }
    }
    
    /// The `EditorSplitViewController` associated with this console.
    @objc var editorSplitViewController: EditorSplitViewController?
    #endif
    
    
    /// Clears screen.
    @objc static func clearConsoleForPath(_ path: String?) {
        DispatchQueue.main.sync {
            #if MAIN
            for console in visibles {
                if console.editorSplitViewController?.editor.document?.fileURL.path == path || path == nil {
                    console.clear()
                }
            }
            #else
            ConsoleViewController.visibles.first?.clear()
            #endif
        }
    }
    
    /// Clears screen.
    @objc func clear() {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.async {
            self.textView.text = ""
            self.console = ""
            semaphore.signal()
        }
        
        if !Thread.current.isMainThread {
            semaphore.wait()
        }
    }
    
    /// The content of the console.
    @objc var console = ""
    
    /// The Text view containing the console.
    @objc var textView = ConsoleTextView()
    
    /// If set to `true`, the user will not be able to input.
    var ignoresInput = false
    
    /// If set to `true`, the user will not be able to input.
    static var ignoresInput = false
    
    /// Add the content of the given notification as `String` to `textView`. Called when the stderr changed or when a script printed from the Pyto module's `print` function`.
    ///
    /// - Parameters:
    ///     - notification: Its associated object should be the `String` added to `textView`.
    @objc func print_(_ notification: Notification) {
        if let output = notification.object as? String {
            DispatchQueue.main.async {
                self.console += output
                
                let attrStr = NSMutableAttributedString(attributedString: self.textView.attributedText)
                attrStr.append(NSAttributedString(string: output, attributes: [.font : UIFont(name: "Menlo", size: 12) ?? UIFont.systemFont(ofSize: 12)]))
                self.textView.attributedText = attrStr
                
                self.textViewDidChange(self.textView)
                self.textView.scrollToBottom()
            }
        }
    }
    
    #if MAIN
    private var scriptPath: String? {
        return editorSplitViewController?.editor.document?.fileURL.path
    }
    #endif
    
    /// The text field used for sending input.
    var movableTextField: MovableTextField?
    
    /// Prompt sent by Python `input(prompt)` function.
    var prompt: String?
    
    /// Returns `false` if input should be ignored.
    var shouldRequestInput: Bool {
        #if MAIN
        let condition = (!self.ignoresInput && !ConsoleViewController.ignoresInput || self.parent is REPLViewController)
        #else
        let condition = (!ignoresInput && !ConsoleViewController.ignoresInput)
        #endif
        
        guard condition else {
            self.ignoresInput = false
            ConsoleViewController.ignoresInput = false
            return false
        }
        
        #if MAIN
        if !(self.parent is REPLViewController) {
            guard let script = scriptPath, Python.shared.isScriptRunning(script) else {
                return false
            }
        }
        #endif
        return true
    }
    
    /// Requests the user for input.
    ///
    /// - Parameters:
    ///     - prompt: The prompt from the Python function
    func input(prompt: String) {
        
        guard shouldRequestInput else {
            return
        }
        
        self.prompt = prompt
        movableTextField?.placeholder = prompt
        movableTextField?.focus()
    }
    
    /// Requests the user for a password.
    ///
    /// - Parameters:
    ///     - prompt: The prompt from the Python function
    func getpass(prompt: String) {
        
        guard shouldRequestInput else {
            return
        }
        
        self.prompt = prompt
        movableTextField?.textField.isSecureTextEntry = true
        movableTextField?.placeholder = prompt
        movableTextField?.focus()
    }
    
    /// Closes the View controller and stops script.
    @objc func close() {
        
        #if MAIN
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        
        if navigationController != nil {
            dismiss(animated: true, completion: {
                self.editorSplitViewController?.editor.stop()
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                    if let line = self.editorSplitViewController?.editor.lineNumberError {
                        self.editorSplitViewController?.editor.lineNumberError = nil
                        self.editorSplitViewController?.editor.showErrorAtLine(line)
                    }
                })
            })
        }
        #else
        exit(0)
        #endif
    }
    
    #if MAIN
    /// Enables `'Done'` if Pip is running.
    @objc static func enableDoneButton() {
        DispatchQueue.main.async {
            for console in self.visibles {
                guard let doneButton = console.editorSplitViewController?.navigationItem.leftBarButtonItem else {
                    return
                }
                
                if #available(iOS 13.0, *) {
                    console.editorSplitViewController?.isModalInPresentation = false
                }
                
                (console.editorSplitViewController as? PipInstallerViewController)?.done = true
                
                if doneButton.action == #selector(PipInstallerViewController.closeViewController) {
                    doneButton.isEnabled = true
                }
            }
        }
    }
    #endif
    
    private static var shared = ConsoleViewController()
    
    /// The visible instance.
    /*@available(*, deprecated, message: "Use scenes APIs instead.") @objc static var visible: ConsoleViewController {
        if Thread.current.isMainThread {
            #if MAIN
            if REPLViewController.shared?.view.window != nil {
                return REPLViewController.shared?.console ?? shared
            } else if PipInstallerViewController.shared?.view.window != nil {
                return PipInstallerViewController.shared?.console ?? shared
            } else if RunModuleViewController.shared?.view.window != nil {
                return RunModuleViewController.shared?.console ?? shared
            } else {
                return shared
            }
            #else
            return shared
            #endif
        } else {
            var console: ConsoleViewController?
            DispatchQueue.main.sync {
                console = ConsoleViewController.visible
            }
            return console ?? shared
        }
    }*/
    
    /// All visible instances.
    @objc static var visibles = [ConsoleViewController]()
    
    // MARK: - Theme
    
    #if MAIN
    /// Setups the View controller interface for given theme.
    ///
    /// - Parameters:
    ///     - theme: The theme to apply.
    func setup(theme: Theme) {
        
        movableTextField?.theme = theme
        
        textView.keyboardAppearance = theme.keyboardAppearance
        textView.backgroundColor = theme.sourceCodeTheme.backgroundColor
        view.backgroundColor = theme.sourceCodeTheme.backgroundColor
        textView.textColor = theme.sourceCodeTheme.color(for: .plain)
    }
    
    /// Called when the user choosed a theme.
    @objc func themeDidChange(_ notification: Notification?) {
        setup(theme: ConsoleViewController.choosenTheme)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    #endif
    
    /// Sets "COLUMNS" and "ROWS" environment variables.
    func updateSize() {
        var columns: Int {
            
            guard let font = textView.font else {
                assertionFailure("Expected font")
                return 0
            }
            
            // TODO: check if the bounds includes the safe area (on iPhone X)
            let viewWidth = textView.bounds.width
            
            let dummyAtributedString = NSAttributedString(string: "X", attributes: [.font: font])
            let charWidth = dummyAtributedString.size().width
            
            // Assumes the font is monospaced
            return Int((viewWidth / charWidth).rounded(.down))
        }
        
        var rows: Int {
            
            guard let font = textView.font else {
                assertionFailure("Expected font")
                return 0
            }
            
            // TODO: check if the bounds includes the safe area (on iPhone X)
            let viewHeight = textView.bounds.height-textView.contentInset.bottom
            
            let dummyAtributedString = NSAttributedString(string: "X", attributes: [.font: font])
            let charHeight = dummyAtributedString.size().height
            
            // Assumes the font is monospaced
            return Int((viewHeight / charHeight).rounded(.down))
        }
        
        print(columns)
        print(rows)
        setenv("COLUMNS", "\(columns)", 1)
        setenv("ROWS", "\(rows)", 1)
    }
    
    // MARK: - UI Presentation
    
    @available(iOS 13.0, *)
    private class ViewController: UIViewController {
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
            
            edgesForExtendedLayout = []
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            view.subviews.first?.frame = view.safeAreaLayoutGuide.layoutFrame
            view.backgroundColor = view.subviews.first?.backgroundColor
            
            navigationItem.leftItemsSupplementBackButton = true
            navigationItem.leftBarButtonItems = view.subviews.first?.buttonItems
        }
        
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            
            coordinator.animate(alongsideTransition: { (_) in
                self.view.subviews.first?.frame.size = size
            }) { (_) in
                self.view.subviews.first?.frame = self.view.safeAreaLayoutGuide.layoutFrame
            }
        }
        
        @objc func keyboardWillShow(notification: NSNotification) {
            guard let userInfo = notification.userInfo else { return }
            
            guard let r = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
            
            let point = (view.window)?.convert(r.origin, to: view) ?? r.origin
            
            view.subviews.first?.frame.size.height = point.y
        }
        
        @objc func keyboardWillHide(notification: NSNotification) {
            view.subviews.first?.frame = view.safeAreaLayoutGuide.layoutFrame
        }
    }
    
    @available(iOS 13.0, *)
    private class NavigationController: UINavigationController {
        
        var pyView: PyView?
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            
            pyView?.isPresented = false
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            navigationBar.backgroundColor = UIColor.systemBackground
        }
    }
    
    /// Returns `true` if any console is presenting an ui.
    @objc public static var isPresentingView: Bool {
        if #available(iOS 13.0, *) {
            for visibile in self.visibles {
                var presenting: Bool {
                    return (visibile.presentedViewController as? NavigationController) != nil
                }
                if Thread.current.isMainThread && presenting {
                    return true
                } else {
                    let semaphore = DispatchSemaphore(value: 0)
                    var flag = false
                    DispatchQueue.main.async {
                        flag = presenting
                        semaphore.signal()
                    }
                    semaphore.wait()
                    if flag {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    /// Shows a given view initialized from Python.
    ///
    /// - Parameters:
    ///     - view: The view to present.
    ///     - path: The path of the script that called this method.
    @available(iOS 13.0, *) @objc public static func showView(_ view: Any, onConsoleForPath path: String?) {
        
        (view as? PyView)?.isPresented = true
        
        DispatchQueue.main.async {
            
            for visibile in self.visibles {
                (visibile.presentedViewController as? NavigationController)?.dismiss(animated: true, completion: nil)
            }
            
            let vc = self.viewController((view as? PyView) ?? PyView(managed: view as! UIView), forConsoleWithPath: path)
            self.showViewController(vc, scriptPath: path, completion: nil)
        }
    }
    
    /// Shows a view controller from Python code.
    ///
    /// - Parameters:
    ///     - viewController: View controller to present.
    ///     - completion: Code called to setup the interface.
    @objc static func showViewController(_ viewController: UIViewController, scriptPath: String? = nil, completion: (() -> Void)?) {
        
        #if WIDGET
        ConsoleViewController.visible.present(viewController, animated: true, completion: completion)
        #elseif !MAIN
        ConsoleViewController.visibles.first?.present(viewController, animated: true, completion: completion)
        #else
        for console in visibles {
            if scriptPath == nil {
                console.present(viewController, animated: true, completion: completion)
                break
            } else if console.editorSplitViewController?.editor.document?.fileURL.path == scriptPath {
                console.present(viewController, animated: true, completion: completion)
            }
        }
        #endif
    }
    
    /// Creates a View controller to present
    ///
    /// - Parameters:
    ///     - view: The View to present initialized from Python.
    ///     - path: The script requesting for the View controller.
    ///
    /// - Returns: A ready to present View controller.
    @available(iOS 13.0, *) @objc public static func viewController(_ view: PyView, forConsoleWithPath path: String?) -> UIViewController {
        
        let vc = ViewController()
        vc.view.addSubview(view.view)
        
        #if MAIN
        
        var console: ConsoleViewController?
        for _console in ConsoleViewController.visibles {
            if path == nil {
                console = _console
                break
            } else if _console.editorSplitViewController?.editor.document?.fileURL.path == path {
                console = _console
                break
            }
        }
        
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: console, action: #selector(ConsoleViewController.closePresentedViewController))
        
        let navVC = NavigationController(rootViewController: vc)
        navVC.pyView = view
        view.viewController = navVC
        
        if view.presentationMode == PyView.PresentationModeFullScreen {
            navVC.modalPresentationStyle = .overFullScreen
        } else if view.presentationMode == PyView.PresentationModeWidget, let viewController = UIStoryboard(name: "Widget Simulator", bundle: Bundle.main).instantiateInitialViewController() {
            
            let widget = (viewController as? UINavigationController)?.viewControllers.first as? WidgetSimulatorViewController
            
            viewController.modalPresentationStyle = .formSheet
            widget?.pyView = view
            
            if let path = path {
                widget?.scriptURL = URL(fileURLWithPath: path)
            }
            
            return viewController
        }
        
        return navVC
        #else
        let navVC = NavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        navVC.modalPresentationStyle = .fullScreen
        navVC.pyView = view
        view.viewController = navVC
        return navVC
        #endif
    }
    
    /// Closes the View controller presented by code.
    @objc func closePresentedViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View controller
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        #if MAIN
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange(_:)), name: ThemeDidChangeNotification, object: nil)
        #endif
        
        edgesForExtendedLayout = []
        
        title = Localizable.console
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.frame.size.height = view.frame.height
        textView.delegate = self
        textView.isEditable = false
        #if !MAIN
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
            textView.backgroundColor = .systemBackground
            textView.textColor = .label
        }
        #endif
        view.addSubview(textView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(print_(_:)), name: .init(rawValue: "DidReceiveOutput"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        movableTextField = MovableTextField(console: self)
    }
    
    #if MAIN
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        themeDidChange(nil)
    }
    #endif
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if MAIN
        if (parent as? REPLViewController)?.reloadREPL == false {
            (parent as? REPLViewController)?.reloadREPL = true
        }
        #endif
        textView.frame = view.safeAreaLayoutGuide.layoutFrame
        textView.frame.size.height -= 44
        textView.frame.origin.y = view.safeAreaLayoutGuide.layoutFrame.origin.y
        
        updateSize()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !ConsoleViewController.visibles.contains(self) {
            ConsoleViewController.visibles.append(self)
        }
        
        if movableTextField == nil {
            movableTextField = MovableTextField(console: self)
            movableTextField?.placeholder = prompt ?? ""
        }
        movableTextField?.show()
        movableTextField?.handler = { text in
            
            let secureTextEntry = self.movableTextField?.textField.isSecureTextEntry ?? false
            self.movableTextField?.textField.isSecureTextEntry = false
            
            guard self.shouldRequestInput else {
                return
            }
            
            PyInputHelper.userInput = text
            if !secureTextEntry {
                Python.shared.output += text
                self.textView.text += "\(self.movableTextField?.placeholder ?? "")\(text)\n"
            } else {
                
                var hiddenPassword = ""
                for _ in 0...text.count {
                    hiddenPassword += "*"
                }
                
                Python.shared.output += text
                self.textView.text += "\(self.movableTextField?.placeholder ?? "")\(hiddenPassword)\n"
            }
            self.textView.scrollToBottom()
        }
        
        var items = [UIBarButtonItem]()
        func appendStop() {
            items.append(UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(close)))
        }
        #if MAIN
        if !(parent is REPLViewController) {
            appendStop()
        }
        #else
        appendStop()
        #endif
        
        navigationItem.rightBarButtonItems = items
        
        #if MAIN
        setup(theme: ConsoleViewController.choosenTheme)
        #endif
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let i = ConsoleViewController.visibles.firstIndex(of: self) {
            ConsoleViewController.visibles.remove(at: i)
        }
        
        movableTextField?.toolbar.removeFromSuperview()
        movableTextField = nil
    }
    
    override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        
        #if MAIN
        themeDidChange(nil)
        #else
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
            navigationController?.view.backgroundColor = .systemBackground
        }
        #endif
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let wasFirstResponder = movableTextField?.textField.isFirstResponder ?? false
        movableTextField?.textField.resignFirstResponder()
        movableTextField?.toolbar.frame.size.width = view.safeAreaLayoutGuide.layoutFrame.width
        movableTextField?.toolbar.frame.origin.x = view.safeAreaInsets.left
        textView.frame = view.safeAreaLayoutGuide.layoutFrame
        textView.frame.size.height = view.safeAreaLayoutGuide.layoutFrame.height-44
        textView.frame.origin.y = view.safeAreaLayoutGuide.layoutFrame.origin.y
        if wasFirstResponder {
            movableTextField?.textField.becomeFirstResponder()
        }
        movableTextField?.toolbar.isHidden = (view.frame.size.height == 0 )
        #if MAIN
        movableTextField?.applyTheme()
        #endif
        updateSize()
    }
    
    open override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(down)),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(up)),
        ]
    }
    
    // MARK: - Keyboard
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if parent?.parent?.modalPresentationStyle != .popover || parent?.parent?.view.frame.width != parent?.parent?.preferredContentSize.width {
            let d = notification.userInfo!
            let r = d[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
            
            let point = (view.window)?.convert(r.origin, to: view) ?? r.origin
            
            textView.frame.size.height = point.y-44
        } else {
            textView.frame.size.height = view.safeAreaLayoutGuide.layoutFrame.height-44
        }
        
        textView.frame.origin.y = view.safeAreaLayoutGuide.layoutFrame.origin.y
        
        textView.scrollToBottom()
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        textView.frame.size.height = view.safeAreaLayoutGuide.layoutFrame.height-44
        textView.frame.origin.y = view.safeAreaLayoutGuide.layoutFrame.origin.y
    }
    
    @objc private func up() {
        movableTextField?.up()
    }
    
    @objc private func down() {
        movableTextField?.down()
    }
    
    // MARK: - Text view delegate
    
    public func textViewDidChange(_ textView: UITextView) {
        console = textView.text
    }
}
