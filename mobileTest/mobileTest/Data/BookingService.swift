//
//  BookingService.swift
//  mobileTest
//
//  Created by apple on 2025/8/19.
//

import Foundation

class BookingService {
    func fetchBookingFromJSON(completion: @escaping (Result<Booking, Error>) -> Void) {
        DispatchQueue.global().async {
            guard let url = Bundle.main.url(forResource: "booking", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                completion(.failure(NSError(domain: "FileNotFound", code: -1)))
                return
            }
            
            do {
                let booking = try JSONDecoder().decode(Booking.self, from: data)
                completion(.success(booking))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
