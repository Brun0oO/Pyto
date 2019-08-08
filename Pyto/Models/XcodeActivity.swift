//
//  XcodeActivity.swift
//  Pyto
//
//  Created by Adrian Labbé on 1/14/19.
//  Copyright © 2019 Adrian Labbé. All rights reserved.
//

import UIKit
import Zip

/// An activity for exporting a script into an Xcode project.
class XcodeActivity: UIActivity {
    
    /// The URL of the Python script to be used as entry point.
    var scriptURL: URL!
    
    /// The View controller which is presenting the UI.
    var viewController: UIViewController?
    
    // MARK: - Activity
    
    override class var activityCategory: UIActivity.Category {
        return .share
    }
    
    override var activityType: UIActivity.ActivityType? {
        guard let bundleId = Bundle.main.bundleIdentifier else {return nil}
        return UIActivity.ActivityType(rawValue: bundleId + "\(self.classForCoder)")
    }
    
    override var activityTitle: String? {
        return "Generate Xcode Project"
    }
    
    override var activityImage: UIImage? {
        return UIImage(imageLiteralResourceName: "Xcode")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return activityItems.count == 1 && (activityItems.first as? URL)?.pathExtension == "py"
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        scriptURL = activityItems.first as? URL
    }
    
    override func perform() {
        
        let title = scriptURL.deletingPathExtension().lastPathComponent
        
        let alert = UIAlertController(title: title, message: "Fill information to generate an Xcode project for building a native application from this script.", preferredStyle: .alert)
        
        var appNameTextField: UITextField!
        var appVersionTextField: UITextField!
        var appBuildNumberTextField: UITextField!
        var appOrganizationID: UITextField!
        
        alert.addTextField { (textField) in
            appNameTextField = textField
            textField.placeholder = "Display name"
            textField.text = title
        }
        
        alert.addTextField { (textField) in
            appVersionTextField = textField
            textField.placeholder = "Version"
            textField.text = "1.0"
        }
        
        alert.addTextField { (textField) in
            appBuildNumberTextField = textField
            textField.placeholder = "Build number"
            textField.text = "1"
        }
        
        alert.addTextField { (textField) in
            appOrganizationID = textField
            textField.placeholder = "Organization Identifier"
            textField.text = UserDefaults.standard.string(forKey: "organizationID") ?? "com.yourcompany"
        }
        
        alert.addAction(UIAlertAction(title: Localizable.create, style: .default, handler: { (_) in
            
            let destURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(title)
            
            let activityAlert = ActivityViewController(message: "")
            self.viewController?.present(activityAlert, animated: true, completion: {
                
                DispatchQueue.global().async {
                    do {
                        
                        for file in ((try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: NSTemporaryDirectory()), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []) {
                            try? FileManager.default.removeItem(at: file)
                        }
                        
                        try Zip.unzipFile(Bundle.main.bundleURL.appendingPathComponent("repo.zip"), destination: destURL, overwrite: true, password: nil)
                        
                        try FileManager.default.moveItem(at: destURL.appendingPathComponent("Python App.xcodeproj"), to: destURL.appendingPathComponent(title).appendingPathExtension("xcodeproj"))
                        
                        let mainURL = destURL.appendingPathComponent("Python App").appendingPathComponent("app").appendingPathComponent("main.py")
                        try FileManager.default.removeItem(at: mainURL)
                        try FileManager.default.copyItem(at: self.scriptURL, to: mainURL)
                        
                        var directories = [
                            (url: self.scriptURL.deletingLastPathComponent(),
                             destination: mainURL.deletingLastPathComponent()),
                            
                            (url: EditorViewController.directory(for: self.scriptURL.deletingLastPathComponent()),
                             destination: mainURL.deletingLastPathComponent()),
                            
                            (url: DocumentBrowserViewController.localContainerURL,
                             destination: destURL.appendingPathComponent("Python App").appendingPathComponent("Documents")),
                            
                            (url: DocumentBrowserViewController.localContainerURL.appendingPathComponent("modules"),
                             destination: destURL.appendingPathComponent("Python App").appendingPathComponent("modules"))
                        ]
                        
                        if let iCloudDrive = DocumentBrowserViewController.iCloudContainerURL {
                            directories.append((url: iCloudDrive, destination: destURL.appendingPathComponent("Python App").appendingPathComponent("iCloudDrive")))
                        }
                        
                        for directory in directories {
                            for file in ((try? FileManager.default.contentsOfDirectory(at: directory.url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []) {
                                
                                if file.path != self.scriptURL.path && file.lastPathComponent != "__pycache__" {
                                    let dest = directory.destination.appendingPathComponent(file.lastPathComponent)
                                    if FileManager.default.fileExists(atPath: dest.path) {
                                        try? FileManager.default.removeItem(at: dest)
                                    }
                                    try FileManager.default.copyItem(at: file, to: dest)
                                }
                            }
                        }
                        
                        let info = NSMutableDictionary()
                        DispatchQueue.main.sync {
                            
                            UserDefaults.standard.set(appOrganizationID.text, forKey: "organizationID")
                            UserDefaults.standard.synchronize()
                            
                            info["CFBundleDevelopmentRegion"] = "en"
                            info["CFBundleDisplayName"] = appNameTextField.text
                            info["CFBundleExecutable"] = "$(EXECUTABLE_NAME)"
                            info["CFBundleIdentifier"] = (appOrganizationID.text ?? "your_company")+"."+((appNameTextField.text ?? "your_app").replacingOccurrences(of: " ", with: "-"))
                            info["CFBundleInfoDictionaryVersion"] = "6.0"
                            info["CFBundleName"] = "$(PRODUCT_NAME)"
                            info["CFBundlePackageType"] = "APPL"
                            info["CFBundleShortVersionString"] = appVersionTextField.text
                            info["CFBundleVersion"] = appBuildNumberTextField.text
                            info["LSRequiresIPhoneOS"] = true
                            info["UILaunchStoryboardName"] = "LaunchScreen"
                            info["UIRequiredDeviceCapabilities"] = ["armv7"]
                            info["UISupportedInterfaceOrientations"] = ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"]
                            info["UISupportedInterfaceOrientations~ipad"] = ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"]
                        }
                        
                        try info.write(to: destURL.appendingPathComponent("Python App").appendingPathComponent("Info.plist"))
                        
                        let zipURL = try Zip.quickZipFiles([destURL], fileName: destURL.lastPathComponent)
                        
                        DispatchQueue.main.async {
                            activityAlert.dismiss(animated: true, completion: {
                                for console in ConsoleViewController.visibles {
                                    let activityVC = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
                                    activityVC.popoverPresentationController?.barButtonItem = console.editorSplitViewController?.editor.shareItem
                                    console.present(activityVC, animated: true, completion: nil)
                                }
                            })
                        }
                    } catch {
                        DispatchQueue.main.async {
                            activityAlert.dismiss(animated: true, completion: {
                                for console in ConsoleViewController.visibles {
                                    let alert = UIAlertController(title: Localizable.Errors.errorCreatingFile, message: error.localizedDescription, preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
                                    console.present(alert, animated: true, completion: nil)
                                }
                            })
                        }
                    }
                }
            })
            
        }))
        
        alert.addAction(UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil))
        
        viewController?.present(alert, animated: true, completion: nil)
        
        activityDidFinish(true)
    }
}
