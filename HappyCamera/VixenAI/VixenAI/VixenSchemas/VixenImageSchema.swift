//
//  VixenImageSchema.swift
//  VixenAI
//
//  图片相关数据模型
//

import Foundation
import HandyJSON

// MARK: - 图片上传响应模型
struct VixenImageUploadResponseSchema: HandyJSON, Codable {
    
    var imageId: String = ""
    var url: String = ""
    var thumbnailUrl: String = ""
    var width: Int = 0
    var height: Int = 0
    var size: Int = 0
    var format: String = ""
    var uploadTime: String = ""
    
    init() {}
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.imageId <-- "image_id"
        mapper <<<
            self.thumbnailUrl <-- "thumbnail_url"
        mapper <<<
            self.uploadTime <-- "upload_time"
    }
    
    // MARK: - 计算属性
    
    /// 图片 URL
    var imageURL: URL? {
        return URL(string: url)
    }
    
    /// 缩略图 URL
    var thumbnailURL: URL? {
        return URL(string: thumbnailUrl)
    }
    
    /// 文件大小描述
    var sizeDescription: String {
        let kb = Double(size) / 1024.0
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        }
        let mb = kb / 1024.0
        return String(format: "%.2f MB", mb)
    }
}

// MARK: - 图片信息模型
struct VixenImageInfoSchema: HandyJSON, Codable {
    
    var imageId: String = ""
    var url: String = ""
    var width: Int = 0
    var height: Int = 0
    var format: String = ""
    var tags: [String] = []
    var description: String = ""
    var userId: String = ""
    var userName: String = ""
    var likeCount: Int = 0
    var viewCount: Int = 0
    var isLiked: Bool = false
    var createTime: String = ""
    
    init() {}
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.imageId <-- "image_id"
        mapper <<<
            self.userId <-- "user_id"
        mapper <<<
            self.userName <-- "user_name"
        mapper <<<
            self.likeCount <-- "like_count"
        mapper <<<
            self.viewCount <-- "view_count"
        mapper <<<
            self.isLiked <-- "is_liked"
        mapper <<<
            self.createTime <-- "create_time"
    }
    
    /// 图片 URL
    var imageURL: URL? {
        return URL(string: url)
    }
    
    /// 标签文本
    var tagsText: String {
        return tags.joined(separator: ", ")
    }
}

// MARK: - 图片列表响应模型
struct VixenImageListResponseSchema: HandyJSON, Codable {
    
    var list: [VixenImageInfoSchema] = []
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

