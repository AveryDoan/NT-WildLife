import Foundation

/// Parses EXIF `DateTimeOriginal` strings ("2026:10:29 14:05:09").
/// EXIF has no time zone unless `OffsetTimeOriginal` ("+09:30") is present,
/// so the phone's zone is assumed otherwise.
public enum ExifDate {
    public static func parse(_ raw: String?, offset: String? = nil, assumedZone: TimeZone) -> Date? {
        guard let raw = raw?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return nil }
        // Cameras write zeros when the clock was never set.
        if raw.hasPrefix("0000") { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = zone(fromOffset: offset) ?? assumedZone
        return formatter.date(from: raw)
    }

    static func zone(fromOffset offset: String?) -> TimeZone? {
        guard let offset = offset?.trimmingCharacters(in: .whitespaces), offset.count == 6 else { return nil }
        let chars = Array(offset)
        guard chars[0] == "+" || chars[0] == "-", chars[3] == ":",
              let hours = Int(String(chars[1...2])), let minutes = Int(String(chars[4...5])),
              hours <= 14, minutes < 60 else { return nil }
        let seconds = (hours * 3600 + minutes * 60) * (chars[0] == "-" ? -1 : 1)
        return TimeZone(secondsFromGMT: seconds)
    }
}
