//
//  Skins+Extensions.swift
//  Skins
//
//  Created by tramp on 2021/4/23.
//

import Foundation

extension Skins {
    /// KeyPath
    public typealias KeyPath = String
}

extension Skins {
    
    /// Color
    public struct Color {
        /// keyPath
        internal let keyPath: KeyPath
        
        /// 构建
        /// - Parameter rawValue: String
        public init(keyPath: KeyPath) {
            self.keyPath = keyPath
        }
        
        /// 构建
        /// - Parameters:
        ///   - module: 模块名
        ///   - key: key
        public init(module: String, key: String) {
            self.keyPath = module + "." + key
        }
        
    }
}

extension Skins.Color: Hashable {}
