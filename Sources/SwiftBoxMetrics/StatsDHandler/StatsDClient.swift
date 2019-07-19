import Foundation
import NIO

public typealias Connection = EventLoopFuture<Channel>

public protocol StatsDClientProtocol {
    func pushMetric(metricLine: String)
}
