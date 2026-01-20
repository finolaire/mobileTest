//
//  VixenConfigModel.swift
//  VixenAI
//
//  配置模型
//

import Foundation
import HandyJSON

struct CameraConfigModel: HandyJSON {
    var CameraType: [CameraTypeModel]?
}

struct CameraTypeModel: HandyJSON {
    var Template: [TemplateModel]?
    var name: String?
    var pic: String?
    var cameraCode: String?
    
    mutating func mapping(mapper: HelpingMapper) {
        // 自定义映射处理不同类型的 cameraCode
        mapper <<< self.cameraCode <-- ["cameraCode"]
    }
    
    // 兼容可能为 Int 的情况
    var cameraCodeString: String {
        return cameraCode ?? ""
    }
}

struct TemplateModel: HandyJSON {
    var group: String?
    var pic_en: [PicEnModel]?
    var pic_zh: [PicZhModel]?
}

// 英文图片模型
struct PicEnModel: HandyJSON {
    var pic_en: String?
    var cameraCode: Int = 0
    var isLock: Bool = false
}

// 中文图片模型
struct PicZhModel: HandyJSON {
    var pic: String?
    var cameraCode: Int = 0
    var isLock: Bool = false
}

// MARK: - 配置加载器
class VixenConfigManager {
    static let shared = VixenConfigManager()
    
    var cameraConfig: CameraConfigModel?
    
    private init() {
        loadConfig()
    }
    
    func loadConfig() {
        guard let path = Bundle.main.path(forResource: "CameraConfig", ofType: "json") else {
            print("❌ [配置] 找不到 CameraConfig.json 文件")
            return
        }
        
        do {
            let jsonString = try String(contentsOfFile: path, encoding: .utf8)
            if let model = CameraConfigModel.deserialize(from: jsonString) {
                self.cameraConfig = model
                print("✅ [配置] 成功解析 CameraConfig.json")
                if let count = model.CameraType?.count {
                    print("📦 [配置] 成功加载 \(count) 个拍摄模式")
                    model.CameraType?.forEach { type in
                        print("  - 模式: \(type.name ?? "未知"), Code: \(type.cameraCodeString)")
                    }
                }
            } else {
                print("❌ [配置] HandyJSON 解析失败")
            }
        } catch {
            print("❌ [配置] 读取文件失败: \(error)")
        }
    }
}
