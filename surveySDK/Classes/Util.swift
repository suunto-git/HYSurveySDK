//
//  Util.swift
//  surveySDK
//
//  Created by Winston on 2023/6/26.
//

import Foundation
import UIKit

public struct Util {
    /**
      计算像素
     */
    public static func parsePx(value: String, max: Int) -> Int {
        if (value.hasSuffix("px")) {
            return Int(value.dropLast(2))!;
        } else if (value.hasSuffix("%")) {
            return Int(Float(value.dropLast(1))! * Float(max) / 100);
        }
        return 0;
    }
    
    public static func optString(config: [String: Any], key: String, fallback: String) -> String {
        return config.index(forKey: key) != nil ? config[key] as! String : fallback
    }
    
    public static func optBool(config: [String: Any], key: String, fallback: Bool) -> Bool {
        return config.index(forKey: key) != nil ? config[key] as! Bool : fallback
    }
    
    /**
     颜色转换 注意FF透明度是放在最后
     */
    public static func colorFromHex(_ hex: String) -> UIColor {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 7: // RGB + Alpha (28-bit, assume last digit is alpha)
            (r, g, b, a) = (int >> 20 & 0xFF, int >> 12 & 0xFF, int >> 4 & 0xFF, (int & 0xF) * 17)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (1, 1, 1, 1)
        }
        return UIColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
    
    public static func convertToString(_ value: Any?) -> String? {
        guard let value = value else { return nil }
        
        if let stringValue = value as? String {
            return stringValue
        } else if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        } else if let intValue = value as? Int {
            return String(intValue)
        } else if let doubleValue = value as? Double {
            return String(doubleValue)
        }
        
        return nil
    }
    
    /**
     显示概率判定
     */
    public static func shouldDisplay(probability: Int) -> Bool {
        // 边界值处理：概率≤0直接不显示，≥100直接显示
        if probability <= 0 {
            return false
        }
        if probability >= 100 {
            return true
        }
        
        // 生成0-99的随机数（包含0和99）
        let randomValue = Int.random(in: 0..<100)
        
        // 随机数小于概率值则显示
        return randomValue < probability
    }

}
