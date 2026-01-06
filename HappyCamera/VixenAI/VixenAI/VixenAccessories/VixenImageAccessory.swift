//
//  VixenImageAccessory.swift
//  VixenAI
//
//  UIImage 扩展方法
//

import UIKit

extension UIImage {
    
    // MARK: - 检查图片是否有透明通道
    /// 检查图片是否有透明通道
    func hasAlpha() -> Bool {
        guard let cgImage = self.cgImage else { return false }
        let alpha = cgImage.alphaInfo
        return (alpha == .first ||
                alpha == .last ||
                alpha == .premultipliedFirst ||
                alpha == .premultipliedLast)
    }
    
    // MARK: - 裁剪图片到指定区域
    /// 返回裁剪到给定边界的图片副本
    /// - Parameter bounds: 裁剪区域
    /// - Returns: 裁剪后的图片
    /// - Note: 此方法会自动处理图片的 scale，但忽略 imageOrientation 设置
    func croppedImage(_ bounds: CGRect) -> UIImage? {
        let scale = max(self.scale, 1.0)
        let scaledBounds = CGRect(
            x: bounds.origin.x * scale,
            y: bounds.origin.y * scale,
            width: bounds.size.width * scale,
            height: bounds.size.height * scale
        )
        
        guard let cgImage = self.cgImage,
              let imageRef = cgImage.cropping(to: scaledBounds) else {
            return nil
        }
        
        let croppedImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: .up)
        return croppedImage
    }
    
    // MARK: - 获取根据方向转换的仿射变换
    /// 返回一个仿射变换，在绘制缩放图片时考虑图片方向
    /// - Parameter newSize: 新尺寸
    /// - Returns: 仿射变换
    private func transformForOrientation(_ newSize: CGSize) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:  // EXIF = 3, 4
            transform = transform.translatedBy(x: newSize.width, y: newSize.height)
            transform = transform.rotated(by: .pi)
            
        case .left, .leftMirrored:  // EXIF = 6, 5
            transform = transform.translatedBy(x: newSize.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:  // EXIF = 8, 7
            transform = transform.translatedBy(x: 0, y: newSize.height)
            transform = transform.rotated(by: -.pi / 2)
            
        default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:  // EXIF = 2, 4
            transform = transform.translatedBy(x: newSize.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:  // EXIF = 5, 7
            transform = transform.translatedBy(x: newSize.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break
        }
        
        return transform
    }
    
    // MARK: - 缩放图片
    /// 返回缩放后的图片副本，考虑图片方向
    /// - Parameters:
    ///   - newSize: 新尺寸
    ///   - transform: 仿射变换
    ///   - transpose: 是否转置
    ///   - quality: 插值质量
    /// - Returns: 缩放后的图片
    private func resizedImage(_ newSize: CGSize,
                              transform: CGAffineTransform,
                              drawTransposed transpose: Bool,
                              interpolationQuality quality: CGInterpolationQuality) -> UIImage? {
        let scale = max(1.0, self.scale)
        let newRect = CGRect(x: 0, y: 0, width: newSize.width * scale, height: newSize.height * scale).integral
        let transposedRect = CGRect(x: 0, y: 0, width: newRect.height, height: newRect.width)
        
        guard let imageRef = self.cgImage else { return nil }
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        guard let bitmap = CGContext(
            data: nil,
            width: Int(newRect.width),
            height: Int(newRect.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(newRect.width) * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        // 旋转和/或翻转图片（如果方向需要）
        bitmap.concatenate(transform)
        
        // 设置缩放时使用的质量级别
        bitmap.interpolationQuality = quality
        
        // 绘制到上下文；这会缩放图片
        bitmap.draw(imageRef, in: transpose ? transposedRect : newRect)
        
        // 从上下文获取缩放后的图片
        guard let newImageRef = bitmap.makeImage() else { return nil }
        let newImage = UIImage(cgImage: newImageRef, scale: self.scale, orientation: .up)
        
        return newImage
    }
    
    // MARK: - 按内容模式缩放图片
    /// 根据给定的内容模式缩放图片，考虑图片方向
    /// - Parameters:
    ///   - contentMode: 内容模式
    ///   - bounds: 边界尺寸
    ///   - quality: 插值质量
    /// - Returns: 缩放后的图片
    func resizedImage(withContentMode contentMode: UIView.ContentMode,
                      bounds: CGSize,
                      interpolationQuality quality: CGInterpolationQuality) -> UIImage? {
        let horizontalRatio = bounds.width / self.size.width
        let verticalRatio = bounds.height / self.size.height
        let ratio: CGFloat
        
        switch contentMode {
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
        default:
            return nil
        }
        
        let newSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
        
        let drawTransposed: Bool
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            drawTransposed = true
        default:
            drawTransposed = false
        }
        
        let transform = transformForOrientation(newSize)
        
        return resizedImage(newSize, transform: transform, drawTransposed: drawTransposed, interpolationQuality: quality)
    }
    
    // MARK: - 添加水印
    /// 在图片右下角添加文本水印
    /// - Parameter text: 水印文字
    /// - Returns: 添加水印后的图片
    func addWatermark(text: String) -> UIImage {
        // 计算水印文字的尺寸
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = (text as NSString).size(withAttributes: attributes)
        
        // 开始图片上下文
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制原始图片
        self.draw(at: .zero)
        
        // 计算水印位置（右下角，留 20pt 边距）
        let watermarkOrigin = CGPoint(
            x: self.size.width - textSize.width - 20,
            y: self.size.height - textSize.height - 20
        )
        
        // 绘制半透明背景
        let backgroundRect = CGRect(
            x: watermarkOrigin.x - 10,
            y: watermarkOrigin.y - 5,
            width: textSize.width + 20,
            height: textSize.height + 10
        )
        UIColor.black.withAlphaComponent(0.5).setFill()
        let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 5)
        path.fill()
        
        // 绘制水印文字
        (text as NSString).draw(at: watermarkOrigin, withAttributes: attributes)
        
        // 获取最终图片
        guard let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return self
        }
        
        return watermarkedImage
    }
}
