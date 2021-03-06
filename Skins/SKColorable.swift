//
//  SKColorable.swift
//  Skins
//
//  Created by tramp on 2021/4/23.
//

import Foundation
import UIKit


/// SKColorable
public protocol SKColorable: Decodable {
    /// color hex string
    var light: String { get }
    /// color hex string
    var dark: String { get }
    
    /// value for SKUserInterfaceStyle
    /// - Parameter interfaceStyle: SKUserInterfaceStyle
    func value(for interfaceStyle: SKUserInterfaceStyle) -> String
}

extension SKColorable {
    
    /// value for SKUserInterfaceStyle
    /// - Parameter interfaceStyle: SKUserInterfaceStyle
    /// - Returns: String
    public func value(for interfaceStyle: SKUserInterfaceStyle) -> String {
        switch interfaceStyle {
        case .dark: return dark
        case .light: return light
        case .unspecified:
            if #available(iOS 13.0, *) {
                return UITraitCollection.current.userInterfaceStyle == .dark ? dark : light
            } else {
                return light
            }
        default: return light
        }
    }
    
    /// color for SKUserInterfaceStyle
    /// - Parameter interfaceStyle: SKUserInterfaceStyle
    /// - Returns: UIColor
    internal func color(for interfaceStyle: SKUserInterfaceStyle) -> UIColor {
        return value(for: interfaceStyle).skin.toColor()
    }
}
