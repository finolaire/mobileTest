//
//  VixenUserSchema.swift
//  VixenAI
//
//  用户数据模型
//

import Foundation
import HandyJSON

// MARK: - 用户模型
struct VixenUserSchema: HandyJSON, Codable {
    
    var userId: String = ""
    var username: String = ""
    var nickname: String = ""
    var avatar: String = ""
    var email: String = ""
    var phone: String = ""
    var gender: Int = 0 // 0: 未知, 1: 男, 2: 女
    var birthday: String = ""
    var signature: String = ""
    var level: Int = 0
    var points: Int = 0
    var vipStatus: Bool = false
    var createTime: String = ""
    var updateTime: String = ""
    
    // HandyJSON 必需的空初始化方法
    init() {}
    
    // MARK: - 自定义映射
    mutating func mapping(mapper: HelpingMapper) {
        // 如果服务器字段名与模型属性名不一致，在这里映射
        // mapper <<<
        //     self.userId <-- "user_id"
        // mapper <<<
        //     self.username <-- "user_name"
    }
    
    // MARK: - 计算属性
    
    /// 性别描述
    var genderDescription: String {
        switch gender {
        case 1:
            return "男"
        case 2:
            return "女"
        default:
            return "未知"
        }
    }
    
    /// 头像 URL
    var avatarURL: URL? {
        return URL(string: avatar)
    }
    
    /// 是否完善了资料
    var isProfileComplete: Bool {
        return !nickname.isEmpty && !avatar.isEmpty
    }
}

// MARK: - 用户登录响应模型
struct VixenLoginResponseSchema: HandyJSON, Codable {
    
    var token: String = ""
    var user: VixenUserSchema?
    var expiresIn: Int = 0
    
    init() {}
}

// MARK: - 用户列表响应模型
struct VixenUserListResponseSchema: HandyJSON, Codable {
    
    var list: [VixenUserSchema] = []
    var total: Int = 0
    var page: Int = 1
    var pageSize: Int = 20
    var hasMore: Bool = false
    
    init() {}
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.pageSize <-- "page_size"
        mapper <<<
            self.hasMore <-- "has_more"
    }
}

