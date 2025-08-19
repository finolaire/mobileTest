////
////  Booking.swift
////  mobileTest
////
////  Created by apple on 2025/8/19.
////
//
//import Foundation
//
//struct Booking: Codable {
//    let shipReference: String
//    let shipToken: String
//    let canIssueTicketChecking: Bool
//    let expiryTime: Double
//    let duration: Int
//    let segments: [Segment]
//}
//
//struct Segment: Codable {
//    let id: Int
//    let originAndDestinationPair: OriginAndDestinationPair
//}
//
//struct OriginAndDestinationPair: Codable {
//    let destination: Location
//    let destinationCity: String
//    let origin: Location
//    let originCity: String
//}
//
//struct Location: Codable {
//    let code: String
//    let displayName: String
//    let url: String
//}

struct Booking: Codable {
    let shipReference: String
    let shipToken: String
    let canIssueTicketChecking: Bool
    let expiryTime: String
    let duration: Int
    let segments: [Segment]
}

struct Segment: Codable {
    let id: Int
    let originAndDestinationPair: OriginAndDestinationPair
}

struct OriginAndDestinationPair: Codable {
    let destination: Location
    let destinationCity: String
    let origin: Location
    let originCity: String
}

struct Location: Codable {
    let code: String
    let displayName: String
    let url: String
}
