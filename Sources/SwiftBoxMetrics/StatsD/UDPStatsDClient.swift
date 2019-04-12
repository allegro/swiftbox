import NIO

import SwiftBoxLogging

private var logger = Logging.make(#file)

public typealias UDPConnectionFactoryType = (UDPConnectionConfig) -> EventLoopFuture<Channel>

public let UDPConnectionFactory: (UDPConnectionConfig) -> EventLoopFuture<Channel> = { config in
    let bootstrap = DatagramBootstrap(group: config.threadGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

    return bootstrap.bind(host: "0.0.0.0", port: 0)
}

/// StatsD Client connection configuration
public struct UDPConnectionConfig {
    /// StatsD server hostname
    var host: String

    /// StatsD server port
    var port: Int

    /// Thread group that will open socket connection
    var threadGroup: MultiThreadedEventLoopGroup

    /// Function used to spawn socket connection
    var connectionFactory: UDPConnectionFactoryType

    public init(
            host: String,
        port: Int = 8125,
        threadGroup: MultiThreadedEventLoopGroup? = nil,
        connectionFactory: @escaping UDPConnectionFactoryType = UDPConnectionFactory
    ) {
        self.host = host
        self.port = port
        self.threadGroup = threadGroup ?? MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.connectionFactory = connectionFactory
    }
}

/// StatsD UDP client
/// Opens a socket connection in separate thread.
/// Client has ability to retry on socket IO failure
public class UDPStatsDClient: StatsDClientProtocol {
    private var config: UDPConnectionConfig
    private var connection: EventLoopFuture<Channel>?

    public required init(config: UDPConnectionConfig) {
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

    /// Actual push metrics function with retries counting.
    /// Gets connection and writes metrics in time format to opened socket channel.
    public func pushMetric(metricLine: String) {
        // TODO(Blejwi): Send with batches
        _ = getConnection().map { channel in
            logger.debug("\(channel)")
            logger.debug("Sending line: \"\(metricLine)\"")

            let remoteAddr = try SocketAddress.newAddressResolving(host: self.config.host, port: self.config.port)
            logger.debug("\(remoteAddr)")

            let line = metricLine + "\n"
            var buffer = channel.allocator.buffer(capacity: line.utf8.count)
            buffer.write(string: line)

            let envelope = AddressedEnvelope(remoteAddress: remoteAddr, data: buffer)
            channel.writeAndFlush(envelope, promise: nil)
        }.thenIfErrorThrowing { error in
            logger.warning(error.localizedDescription)
            logger.warning(String(describing: error))
        }
    }
}
