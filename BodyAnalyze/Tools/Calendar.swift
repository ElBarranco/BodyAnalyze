import Foundation

extension Calendar {
    /// Retourne le début de la semaine (lundi) pour une date donnée
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
