//
//  Skins.swift
//  Skins
//
//  Created by tramp on 2021/4/23.
//

import Foundation
import UIKit

/// Skins
public class Skins: NSObject {
    
    // MARK: - 公开属性
    
    /// single object of Skins
    public static let shared: Skins = .init()
    ///  current interface style SKUserInterfaceStyle
    public private(set) var interfaceStyle: SKUserInterfaceStyle = .unspecified
    /// isDark
    public var isDark: Bool {
        switch interfaceStyle {
        case .dark: return true
        case .light: return false
        case .unspecified:
            if #available(iOS 13.0, *) {
                return UITraitCollection.current.userInterfaceStyle == .dark
            } else {
                return false
            }
        default:
            return false
        }
    }
    // MARK: - 私有属性
    
    /// [ColorKey: SKColorable]
    private lazy var colors: [Color: SKColorable] = [:]
    /// NSMapTable<NSObject, NSMutableDictionary>
    private lazy var map: NSMapTable<AnyObject, NSMutableDictionary> = .init(keyOptions: .weakMemory, valueOptions: .strongMemory)
    /// NSLock
    private lazy var lock: NSLock = .init()
    /// SKUserInterfaceStyle
    private var _interfaceStyle: SKUserInterfaceStyle {
        let defaultKey = SKUserInterfaceStyle.userDefaultsKey
        if let data = UserDefaults.standard.data(forKey: defaultKey),
           let style = try? JSONDecoder.init().decode(SKUserInterfaceStyle.self, from: data)  {
            return style
        } else {
            return .unspecified
        }
    }
    
    // MARK: - 生命周期
    
    /// 构建
    private override init() {
        super.init()
        interfaceStyle = _interfaceStyle
        // 方法交换
        if #available(iOS 13.0, *),
           let m1 = class_getInstanceMethod(Skins.self, #selector(Skins.traitCollectionDidChange(_:))),
           let m2 = class_getInstanceMethod(UIScreen.self, #selector(UIScreen.traitCollectionDidChange(_:))) {
            method_exchangeImplementations(m1, m2)
        }
        
    }
    
    /// traitCollectionDidChange
    /// - Parameter previousTraitCollection: UITraitCollection
    @available(iOS 13.0, *)
    @objc dynamic func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // 方法交换后的结果， 运行时执行 UIScreen.traitCollectionDidChange(_:)
        Skins.shared.perform(#selector(Skins.traitCollectionDidChange(_:)), with: previousTraitCollection)
        // 更新SKUserInterfaceStyle
        if Skins.shared.interfaceStyle == .unspecified, UITraitCollection.current.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            do {
                try Skins.shared.change(style: .unspecified)
            } catch {
                #if DEBUG
                print(error)
                #endif
            }
        }
    }
}

extension Skins {
    
    /// setup for skins
    /// - Parameters:
    ///   - colorType: color type
    ///   - fileUrl: url of plist file
    /// - Throws: Error
    @discardableResult
    public func setup<T: SKColorable>(colorType: T.Type, fileUrl: URL) throws -> Self {
        guard let dict = NSDictionary.init(contentsOf: fileUrl) as? [String: Any] else {
            throw SKError.init("can not paser plist file ....")
        }
        let decoder: JSONDecoder = .init()
        for (module, value) in dict where value is [String: Any] {
            guard let value = value as? [String: Any] else { continue }
            for (key, value) in value {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                let color = try decoder.decode(colorType.self, from: data)
                let colorKey: Color = .init(module: module, key: key)
                colors[colorKey] = color
            }
        }
        return self
    }
    
    /// color for key
    /// - Parameter key: ColorKey
    /// - Returns: SKColorable
    public func color(for key: Color) -> SKColorable? {
        return colors[key]
    }
    
    /// change style
    /// - Parameter interfaceStyle: SKUserInterfaceStyle
    public func change(style interfaceStyle: SKUserInterfaceStyle, animated: Bool = true) throws {
        guard let map = map as? NSMapTable<AnyObject, AnyObject>, let dicts = NSAllMapTableValues(map) as? [NSDictionary] else {
            throw SKError.init("NSMapTable covert fail")
        }
        self.interfaceStyle = interfaceStyle
        // save style
        try save(style: interfaceStyle)
        
        /// execute
        func execute() {
            // above 13.0
            if #available(iOS 13.0, *) {
                for window in UIApplication.shared.windows {
                    window.overrideUserInterfaceStyle = interfaceStyle.overrideUserInterfaceStyle
                }
            }
            for dict in dicts {
                for value in dict.allValues where value is SKAction {
                    guard let action = value as? SKAction else { continue }
                    action.run(with: interfaceStyle)
                }
            }
        }
        // execute
        if animated == true {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear) {
                execute()
            }
        } else {
            execute()
        }
    }
    
    /// save  interface to user defaults
    /// - Parameter interfaceStyle: SKUserInterfaceStyle
    private func save(style interfaceStyle: SKUserInterfaceStyle) throws {
        let defaultKey = SKUserInterfaceStyle.userDefaultsKey
        if interfaceStyle == .unspecified {
            UserDefaults.standard.setValue(nil, forKey: defaultKey)
            UserDefaults.standard.synchronize()
        } else {
            let data = try JSONEncoder.init().encode(interfaceStyle)
            UserDefaults.standard.setValue(data, forKey: defaultKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// log
    public func log() {
        #if DEBUG
        guard let map = map as? NSMapTable<AnyObject, AnyObject> else { return }
        let contents = NSStringFromMapTable(map)
        print(contents)
        #endif
    }
}

extension Skins {
    
    /// set tuple for target
    /// - Parameters:
    ///   - tuple: (key: SKAction.Key, action: SKAction)
    ///   - target: NSObject
    public func set(_ tuple: (key: SKAction.Key, action: SKAction), for target: NSObject) {
        lock.skin.safe {
            if let dict = map.object(forKey: target) {
                dict[tuple.key] = tuple.action
                // map.setObject(dict, forKey: target)
            } else {
                let dict: NSMutableDictionary = [tuple.key: tuple.action]
                map.setObject(dict, forKey: target)
            }
        }
    }
    
    /// action for key on target
    /// - Parameters:
    ///   - key: SKAction.Key
    ///   - target: NSObject
    /// - Returns: SKAction?
    internal func action(for key: SKAction.Key, onTarget target: NSObject) -> SKAction? {
        return lock.skin.safe { () -> SKAction? in
            guard let dict = map.object(forKey: target) else { return nil }
            guard let action = dict.object(forKey: key) as? SKAction else { return nil }
            return action
        }
    }
}
