//
//  PySwitch.swift
//  Pyto
//
//  Created by Adrian Labbé on 17-07-19.
//  Copyright © 2019 Adrian Labbé. All rights reserved.
//

import UIKit

@available(iOS 13.0, *) @objc public class PySwitch: PyControl {
    
    /// The switch associated with this object.
    @objc public var _switch: UISwitch {
        return get {
            return self.managed as! UISwitch
        }
    }
    
    @objc public var isOn: Bool {
        get {
            return get {
                return self._switch.isOn
            }
        }
        
        set {
            set {
                self._switch.isOn = newValue
            }
        }
    }
    
    
    @objc public func setOn(_ on: Bool, animated: Bool) {
        set {
            self._switch.setOn(on, animated: animated)
        }
    }
    
    @objc public var onColor: PyColor? {
        get {
            return get {
                if let color = self._switch.onTintColor {
                    return PyColor(managed: color)
                } else {
                    return nil
                }
            }
        }
        
        set {
            set {
                self._switch.onTintColor = newValue?.color
            }
        }
    }
    
    @objc public var thumbColor: PyColor? {
        get {
            return get {
                if let color = self._switch.thumbTintColor {
                    return PyColor(managed: color)
                } else {
                    return nil
                }
            }
        }
        
        set {
            set {
                self._switch.thumbTintColor = newValue?.color
            }
        }
    }
    
    @objc override class func newView() -> PyView {
        let pySwitch = PySwitch()
        pySwitch.managed = get {
            let _switch = UISwitch()
            _switch.sizeToFit()
            _switch.addTarget(pySwitch, action: #selector(PyControl.callAction), for: .valueChanged)
            return _switch
        }
        return pySwitch
    }
}
