enum WorkoutDiscipline: String, CaseIterable, Identifiable {
    case running
    case walking
    case hiking
    case cycling
    case swimming
    case strength
    case hiit
    case yoga
    case mobility
    case other

    var id: String { self.rawValue }

    var emoji: String {
        switch self {
        case .running: return "🏃‍♂️"
        case .walking: return "🚶‍♂️"
        case .hiking: return "🥾"
        case .cycling: return "🚴‍♀️"
        case .swimming: return "🏊‍♂️"
        case .strength: return "🏋️‍♂️"
        case .hiit: return "🥊"
        case .yoga: return "🧘‍♀️"
        case .mobility: return "🧎‍♂️"
        case .other: return "❓"
        }
    }
}
