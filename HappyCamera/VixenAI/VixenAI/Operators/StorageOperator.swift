//
//  VixenStorageOperator.swift
//  VixenAI
//
//  本地存储管理器
//

import Foundation

// MARK: - 本地存储管理器
class VixenStorageOperator {
    
    static let shared = VixenStorageOperator()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - UserDefaults 存储
    
    /// 保存值
    func save<T>(_ value: T, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }
    
    /// 获取值
    func get<T>(_ type: T.Type, forKey key: String) -> T? {
        return userDefaults.object(forKey: key) as? T
    }
    
    /// 获取字符串
    func getString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    /// 获取整数
    func getInt(forKey key: String) -> Int {
        return userDefaults.integer(forKey: key)
    }
    
    /// 获取布尔值
    func getBool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    /// 获取浮点数
    func getDouble(forKey key: String) -> Double {
        return userDefaults.double(forKey: key)
    }
    
    /// 删除值
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }
    
    /// 清空所有数据
    func clearAll() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleIdentifier)
            userDefaults.synchronize()
        }
    }
    
    // MARK: - JSON 编码存储
    
    /// 保存 Codable 对象
    func saveObject<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            userDefaults.set(encoded, forKey: key)
            userDefaults.synchronize()
        }
    }
    
    /// 获取 Codable 对象
    func getObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
    
    // MARK: - 文件存储
    
    /// 获取文档目录
    var documentsDirectory: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// 获取缓存目录
    var cachesDirectory: URL {
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    /// 获取临时目录
    var temporaryDirectory: URL {
        return fileManager.temporaryDirectory
    }
    
    /// 保存文件
    func saveFile(data: Data, fileName: String, directory: URL? = nil) -> URL? {
        let targetDirectory = directory ?? documentsDirectory
        let fileURL = targetDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("保存文件失败: \(error)")
            return nil
        }
    }
    
    /// 读取文件
    func readFile(fileName: String, directory: URL? = nil) -> Data? {
        let targetDirectory = directory ?? documentsDirectory
        let fileURL = targetDirectory.appendingPathComponent(fileName)
        
        return try? Data(contentsOf: fileURL)
    }
    
    /// 删除文件
    func deleteFile(fileName: String, directory: URL? = nil) -> Bool {
        let targetDirectory = directory ?? documentsDirectory
        let fileURL = targetDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            print("删除文件失败: \(error)")
            return false
        }
    }
    
    /// 文件是否存在
    func fileExists(fileName: String, directory: URL? = nil) -> Bool {
        let targetDirectory = directory ?? documentsDirectory
        let fileURL = targetDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// 获取文件大小
    func fileSize(fileName: String, directory: URL? = nil) -> Int64? {
        let targetDirectory = directory ?? documentsDirectory
        let fileURL = targetDirectory.appendingPathComponent(fileName)
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path) else {
            return nil
        }
        
        return attributes[.size] as? Int64
    }
    
    /// 清空缓存目录
    func clearCaches() {
        let cacheURL = cachesDirectory
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("清空缓存失败: \(error)")
        }
    }
    
    /// 获取缓存大小
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        let cacheURL = cachesDirectory
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey])
            for fileURL in fileURLs {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        } catch {
            print("获取缓存大小失败: \(error)")
        }
        
        return totalSize
    }
}

// MARK: - 常用存储 Key
extension VixenStorageOperator {
    
    struct Keys {
        static let userToken = "VixenUserToken"
        static let userId = "VixenUserId"
        static let userName = "VixenUserName"
        static let isFirstLaunch = "VixenIsFirstLaunch"
        static let lastLoginTime = "VixenLastLoginTime"
    }
}

