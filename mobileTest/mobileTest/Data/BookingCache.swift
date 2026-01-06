//
//  BookingCache.swift
//  mobileTest
//
//  Created by apple on 2025/8/19.
//

import Foundation

class BookingCache {
    
    private let cacheFileName = "booking_cache.json"
    
    private var cacheURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(cacheFileName)
    }
    
    func saveBooking(_ booking: Booking) {
        do {
            let data = try JSONEncoder().encode(booking)
            try data.write(to: cacheURL)
        } catch {
        }
    }

    func loadBooking() -> Booking? {
        do {
            let data = try Data(contentsOf: cacheURL)
            let booking = try JSONDecoder().decode(Booking.self, from: data)
            return booking
        } catch {
            return nil
        }
    }
    
    func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
}

