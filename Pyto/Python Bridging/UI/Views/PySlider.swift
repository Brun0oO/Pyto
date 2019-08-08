//
//  PySlider.swift
//  Pyto
//
//  Created by Adrian Labbé on 17-07-19.
//  Copyright © 2019 Adrian Labbé. All rights reserved.
//

import UIKit

@available(iOS 13.0, *) @objc public class PySlider: PyControl {
    
    /// The slider associated with this object.
    @objc public var slider: UISlider {
        return get {
            return self.managed as! UISlider
        }
    }
    
    @objc public var minimumValue: Double {
        get {
            return get {
                return Double(self.slider.minimumValue)
            }
        }
        
        set {
            set {
                self.slider.minimumValue = Float(newValue)
            }
        }
    }
    
    @objc public var maximumValue: Double {
        get {
            return get {
                return Double(self.slider.maximumValue)
            }
        }
        
        set {
            set {
                self.slider.maximumValue = Float(newValue)
            }
        }
    }
    
    @objc public func setValue(_ value: Double, animated: Bool) {
        set {
            self.slider.setValue(Float(value), animated: animated)
        }
    }
    
    @objc public var value: Double {
        get {
            return get {
                return Double(self.slider.value)
            }
        }
        
        set {
            set {
                self.slider.value = Float(newValue)
            }
        }
    }
    
    @objc public var minimumTrackColor: PyColor? {
        get {
            return get {
                if let color = self.slider.minimumTrackTintColor {
                    return PyColor(managed: color)
                } else {
                    return nil
                }
            }
        }
        
        set {
            set {
                self.slider.minimumTrackTintColor = newValue?.color
            }
        }
    }
    
    @objc public var maximumTrackColor: PyColor? {
        get {
            return get {
                if let color = self.slider.maximumTrackTintColor {
                    return PyColor(managed: color)
                } else {
                    return nil
                }
            }
        }
        
        set {
            set {
                self.slider.maximumTrackTintColor = newValue?.color
            }
        }
    }
    
    @objc public var thumbColor: PyColor? {
        get {
            return get {
                if let color = self.slider.thumbTintColor {
                    return PyColor(managed: color)
                } else {
                    return nil
                }
            }
        }
        
        set {
            set {
                self.slider.thumbTintColor = newValue?.color
            }
        }
    }
    
    @objc override class func newView() -> PyView {
        let pySlider = PySlider()
        pySlider.managed = get {
            let slider = UISlider()
            slider.sizeToFit()
            slider.addTarget(pySlider, action: #selector(PyControl.callAction), for: .valueChanged)
            return slider
        }
        return pySlider
    }
}

