import Foundation
import NIO

public typealias Connection = EventLoopFuture<Channel>

public protocol StatsDClientProtocol {
    func pushMetric(metricLine: String)
}

extension TimeAmount {
    public func toMicroseconds() -> Double {
        return Double(nanoseconds) / 1000
    }

    public func toMilliseconds() -> Double {
        return toMicroseconds() / 1000
    }

    public func toSeconds() -> Double {
        return toMilliseconds() / 1000
    }
}