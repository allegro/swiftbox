public protocol StatsDMetric {
    func getStatsDLine() -> String
}

public struct TimerMetric: StatsDMetric {
    let name: String
    let value: Double

    public func getStatsDLine() -> String {
        return "\(name):\(value)|ms"
    }
}

public struct CounterMetric: StatsDMetric {
    let name: String
    let value: Int64

    public func getStatsDLine() -> String {
        return "\(name):\(value)|c"
    }
}

public struct GaugeMetric: StatsDMetric {
    let name: String
    let value: Double
    let type: GaugeActionType

    enum GaugeActionType: String {
        case set = ""
        case increment = "+"
        case decrement = "-"
    }

    public func getStatsDLine() -> String {
        return "\(name):\(type.rawValue)\(value)|g"
    }
}
