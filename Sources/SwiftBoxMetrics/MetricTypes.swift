public protocol Metric {}

public struct TimerMetric: Metric {
    let name: String
    let value: Double
}

public struct CounterMetric: Metric {
    let name: String
    let value: Int
}

public struct GaugeMetric: Metric {
    let name: String
    let value: Int
    let type: GaugeActionType

    enum GaugeActionType: String {
        case set = ""
        case increment = "+"
        case decrement = "-"
    }
}