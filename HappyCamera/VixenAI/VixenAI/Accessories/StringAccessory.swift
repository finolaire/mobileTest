//
//  VixenStringAccessory.swift
//  VixenAI
//
//  字符串处理扩展工具
//

import Foundation
import UIKit

// MARK: - String 扩展
extension String {
    
    /// 移除首尾空格和换行
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 是否为空（包括只有空格的情况）
    var isBlank: Bool {
        return self.trimmed.isEmpty
    }
    
    /// 是否不为空
    var isNotBlank: Bool {
        return !isBlank
    }
    
    /// 计算字符串长度（中文算2个字符）
    var length: Int {
        var length = 0
        for char in self {
            let str = String(char)
            if str.lengthOfBytes(using: .utf8) == 3 {
                length += 2
            } else {
                length += 1
            }
        }
        return length
    }
    
    /// 验证是否是有效的邮箱
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// 验证是否是有效的手机号（中国）
    var isValidPhone: Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self)
    }
    
    /// 验证是否是有效的身份证号
    var isValidIDCard: Bool {
        let idCardRegex = "^[1-9]\\d{5}(18|19|20)\\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\\d{3}[0-9Xx]$"
        let idCardPredicate = NSPredicate(format: "SELF MATCHES %@", idCardRegex)
        return idCardPredicate.evaluate(with: self)
    }
    
    /// 手机号脱敏
    var maskedPhone: String {
        guard self.count == 11 else { return self }
        let start = self.prefix(3)
        let end = self.suffix(4)
        return "\(start)****\(end)"
    }
    
    /// 身份证脱敏
    var maskedIDCard: String {
        guard self.count >= 14 else { return self }
        let start = self.prefix(6)
        let end = self.suffix(4)
        return "\(start)********\(end)"
    }
    
    /// Base64 编码
    var base64Encoded: String? {
        return self.data(using: .utf8)?.base64EncodedString()
    }
    
    /// Base64 解码
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// MD5 加密（注意：仅用于非安全场景，如文件校验等）
    var md5: String {
        guard let data = self.data(using: .utf8) else { return self }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        data.withUnsafeBytes { buffer in
            #if compiler(>=5.5)
            _ = CC_MD5(buffer.baseAddress, CC_LONG(buffer.count), &digest)
            #else
            _ = CC_MD5(buffer.baseAddress, CC_LONG(buffer.count), &digest)
            #endif
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// 获取字符串的尺寸
    func size(withFont font: UIFont, maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let rect = self.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }
    
    /// 高亮关键词
    func highlightKeywords(_ keywords: [String], color: UIColor = .red) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        
        for keyword in keywords {
            var range = (self as NSString).range(of: keyword)
            while range.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor, value: color, range: range)
                let startRange = range.location + range.length
                let searchRange = NSRange(location: startRange, length: (self as NSString).length - startRange)
                range = (self as NSString).range(of: keyword, options: [], range: searchRange)
            }
        }
        
        return attributedString
    }
    
    /// 转换为 URL
    var toURL: URL? {
        return URL(string: self)
    }
    
    /// URL 编码
    var urlEncoded: String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    /// URL 解码
    var urlDecoded: String? {
        return self.removingPercentEncoding
    }
}

// MARK: - 需要导入 CommonCrypto
import CommonCrypto

// MARK: - NSAttributedString 扩展
extension NSAttributedString {
    
    /// 获取尺寸
    func size(maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let size = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let rect = self.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }
}

