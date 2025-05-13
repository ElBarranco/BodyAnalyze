import SwiftUI
import Charts

struct WeeklyCaloriesLineChartView: View {
    let activeCalories: [Date: Double]
    let basalCalories: [Date: Double]
    
    @State private var selectedWeekLabel: String? = nil
    
    struct WeeklyCalorieData: Identifiable {
        let id = UUID()
        let weekLabel: String
        let totalCalories: Double
        let isCurrentWeek: Bool
    }
    
    private var currentWeekLabel: String {
        let calendar = Calendar.current
        let today = Date()
        let week = calendar.component(.weekOfYear, from: today)
        return "S\(week)"
    }
    
    private var weeklyData: [WeeklyCalorieData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: today))!
        
        let last6Weeks = (0..<6).compactMap {
            calendar.date(byAdding: .weekOfYear, value: -$0, to: thisWeekStart)
        }.reversed()
        
        return last6Weeks.map { rawWeekStart in
            let weekStart = calendar.startOfDay(for: rawWeekStart)
            let currentWeekStart = thisWeekStart
            let isCurrent = (weekStart == currentWeekStart)
            
            let weekEnd = isCurrent ? today : calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let cleanEnd = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: weekEnd)!)
            let weekRange = DateInterval(start: weekStart, end: cleanEnd)
            
            let activeTotal = activeCalories
                .map { (calendar.startOfDay(for: $0.key), $0.value) }
                .filter { weekRange.contains($0.0) }
                .map(\.1)
                .reduce(0, +)
            
            let basalTotal = basalCalories
                .map { (calendar.startOfDay(for: $0.key), $0.value) }
                .filter { weekRange.contains($0.0) }
                .map(\.1)
                .reduce(0, +)
            
            let weekLabel = "S\(calendar.component(.weekOfYear, from: weekStart))"
            
            return WeeklyCalorieData(
                weekLabel: weekLabel,
                totalCalories: activeTotal + basalTotal,
                isCurrentWeek: isCurrent
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("📊 Calories hebdomadaires")
                .font(.headline)
            
            Chart {
                ForEach(weeklyData) { item in
                    let isSelected = item.weekLabel == selectedWeekLabel
                    let color = item.isCurrentWeek ? Color.orange : Color.red
                    
                    LineMark(
                        x: .value("Semaine", item.weekLabel),
                        y: .value("Calories", item.totalCalories)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color)
                    
                    PointMark(
                        x: .value("Semaine", item.weekLabel),
                        y: .value("Calories", item.totalCalories)
                    )
                    .symbolSize(isSelected ? 150 : 80)
                    .foregroundStyle(color)
                    .annotation(position: .top) {
                        if isSelected {
                            HStack(spacing: 4) {
                                Text("\(Int(item.totalCalories)) kcal")
                                if item.isCurrentWeek {
                                    Text("⏳")
                                }
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color)
                        }
                    }
                }
            }
            .frame(height: 240)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let x = value.location.x
                                    if let label: String = proxy.value(atX: x) {
                                        selectedWeekLabel = label
                                    }
                                }
                        )
                }
            }
            
            Text("Tendance sur 6 semaines")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        
    }
}
