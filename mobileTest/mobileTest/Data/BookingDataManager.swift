//
//  BookingDataManager.swift
//  mobileTest
//
//  Created by apple on 2025/8/19.
//

import Foundation

protocol BookingProviding {
    func fetchBooking(forceRefresh: Bool, completion: @escaping (Result<Booking, Error>) -> Void)
}

final class BookingDataManager: BookingProviding {
    static let shared = BookingDataManager()
    private let service = BookingService()
    private let cache = BookingCache()
    private init() {}

    func fetchBooking(forceRefresh: Bool = false, completion: @escaping (Result<Booking, Error>) -> Void) {
        if let cached = cache.loadBooking(), !forceRefresh {
      
            if cached.isExpired {
                //过期，用旧数据展示
                completion(.success(cached))
                //同时异步刷新
                refreshFromService { completion($0) }
            } else {
                //未过期直接使用缓存
                completion(.success(cached))
                //刷新保持最新数据
                refreshFromService { _ in }
            }
            return
        }

        //没有缓存或者强制刷新，直接走 Service 获取数据
        refreshFromService { completion($0) }
    }

    private func refreshFromService(completion: @escaping (Result<Booking, Error>) -> Void) {
        service.fetchBookingFromJSON { [weak self] result in
            switch result {
            case .success(let booking):
                self?.cache.saveBooking(booking)
                completion(.success(booking))
            case .failure(let error):
                //1.5.错误处理
                if let cached = self?.cache.loadBooking() {
                    completion(.success(cached))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}

extension Booking {
    var isExpired: Bool {
        if let expiry = Double(expiryTime) {
            // 当前时间 >= expiryTime 就算过期
            return Date() >= Date(timeIntervalSince1970: expiry)
        }
        return false
    }
}
