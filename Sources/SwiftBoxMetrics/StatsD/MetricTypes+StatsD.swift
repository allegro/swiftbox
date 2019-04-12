import Foundation

public protocol StatsDMetric: Metric {
    func getStatsDLine() -> String
}

extension TimerMetric: StatsDMetric {
    public func getStatsDLine() -> String {
        return "\(name):\(value)|ms"
    }
}

extension CounterMetric: StatsDMetric {
    public func getStatsDLine() -> String {
        return "\(name):\(value)|c"
    }
}

extension GaugeMetric: StatsDMetric {
    public func getStatsDLine() -> String {
        return "\(name):\(type.rawValue)\(value)|g"
    }
}