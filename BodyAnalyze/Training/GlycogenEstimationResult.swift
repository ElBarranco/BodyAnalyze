import Foundation

struct GlycogenEstimationResult {
    let reserveMax: Double
    let glycogenUsed: Double
    let remaining: Double
    let percentageRemaining: Double
    let timeSeries: [Double]
}
