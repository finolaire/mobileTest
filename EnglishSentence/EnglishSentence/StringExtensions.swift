import Foundation

extension String {
    func ranges(of substring: String) -> [NSRange] {
        var ranges: [NSRange] = []
        var searchRange = self.startIndex..<self.endIndex
        while let range = self.range(of: substring, options: [], range: searchRange) {
            let nsRange = NSRange(range, in: self)
            ranges.append(nsRange)
            
            // Move search range to start after the found match
            if range.upperBound < self.endIndex {
                searchRange = range.upperBound..<self.endIndex
            } else {
                break
            }
        }
        return ranges
    }
}
