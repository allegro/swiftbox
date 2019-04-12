import Foundation
import NIO

import SwiftBoxLogging

private var logger = Logging.make(#file)

public typealias TCPConnectionFactoryType = (TCPConnectionConfig) -> EventLoopFuture<Channel>

public let TCPConnectionFactory: (TCPConnectionConfig) -> EventLoopFuture<Channel> = { config in
    let bootstrap = ClientBootstrap(group: config.threadGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.connectTimeout, value: config.connectionTimeout)

    return bootstrap.connect(host: config.host, port: config.port)
}

/// StatsD Client connection configuration
public struct TCPConnectionConfig {
    /// StatsD server hostname
    var host: String

    /// StatsD server port
    var port: Int

    /// Timeout for socket connection
    var connectionTimeout: TimeAmount

    /// Thread group that will open socket connection
    var threadGroup: MultiThreadedEventLoopGroup

    /// How many times metric should be resent before failing
    var maxPushRetries: Int

    /// Time amount that worker should wait between resending metrics on fail
    var pushRetryInterval: TimeAmount

    /// Function used to spawn socket connection
    var connectionFactory: TCPConnectionFactoryType

    public init(
            host: String,
        port: Int = 8125,
        connectionTimeout: TimeAmount = TimeAmount.milliseconds(1000),
        threadGroup: MultiThreadedEventLoopGroup? = nil,
        maxPushRetries: Int = 5,
        pushRetryInterval: TimeAmount = TimeAmount.milliseconds(500),
        connectionFactory: @escaping TCPConnectionFactoryType = TCPConnectionFactory
    ) {
        self.host = host
        self.port = port
        self.connectionTimeout = connectionTimeout
        self.threadGroup = threadGroup ?? MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.maxPushRetries = maxPushRetries
        self.pushRetryInterval = pushRetryInterval
        self.connectionFactory = connectionFactory
    }
}

/// StatsD TCP client
/// Opens a socket connection in separate thread.
/// Client has ability to retry on socket IO failure
public class TCPStatsDClient: StatsDClientProtocol {
    private var config: TCPConnectionConfig
    private var connection: EventLoopFuture<Channel>?

    public required init(config: TCPConnectionConfig) {
        self.config = config
    }

    /// Getter method for connection
    /// If connection is already defined returns it or uses connectionFactory to create new one when not found.
    internal func getConnection() -> EventLoopFuture<Channel> {
        guard let connection = self.connection else {
            logger.debug("Opening connection")
            self.connection = config.connectionFactory(config)
            return self.connection!
        }

        logger.debug("Returning existing connection")
        return connection
    }

    /// Push metric
    public func pushMetric(metricLine: String) {
        pushMetric(metricLine: metricLine, retriesLeft: config.maxPushRetries)
    }

    /// Actual push metrics function with retries counting.
    /// Gets connection and writes metrics in time format to opened socket channel.
    public func pushMetric(metricLine: String, retriesLeft: Int) {
        // TODO(Blejwi): Send with batches
        _ = getConnection().flatMap { channel in
            logger.debug("Sending line: \"\(metricLine)\", retries left: \(retriesLeft)")
            let line = metricLine + "\n"
            var buffer = channel.allocator.buffer(capacity: line.utf8.count)
            buffer.write(string: line)
            return channel.writeAndFlush(buffer)
        }.thenIfErrorThrowing { error in
            logger.warning(error.localizedDescription)
            self.connection = nil
            if retriesLeft > 0 {
                Thread.sleep(forTimeInterval: self.config.pushRetryInterval.toSeconds())
                self.pushMetric(metricLine: metricLine, retriesLeft: retriesLeft - 1)
            } else {
                logger.error("Couldn't send metric to StatsD, tried \(self.config.maxPushRetries) times")
            }
        }
    }
}
