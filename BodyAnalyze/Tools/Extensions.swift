import Foundation

extension Double {
    func asHourMinuteString() -> String {
        let hours = Int(self)
        let minutes = Int((self - Double(hours)) * 60)
        return String(format: "%dh%02d", hours, minutes)
    }
}
