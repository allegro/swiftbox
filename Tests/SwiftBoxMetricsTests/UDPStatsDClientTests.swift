import Foundation
import XCTest

@testable import NIO
@testable import SwiftBoxMetrics

class UDPStatsDClientTests: XCTestCase {

    private func buildChannel(loop: EventLoopGroup) throws -> Channel {
        return try DatagramBootstrap(group: loop)
                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .channelInitializer { channel in
                    channel.pipeline.add(name: "ByteReadRecorder", handler: DatagramReadRecorder<ByteBuffer>())
                }
                .bind(host: "127.0.0.1", port: 0)
                .wait()
    }

    func testClientShouldPushMetrics() throws {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            try! eventLoop.syncShutdownGracefully()
        }

        let channelSender = try self.buildChannel(loop: eventLoop)
        let channelReceiver = try self.buildChannel(loop: eventLoop)
        let client = UDPStatsDClient(
                config: UDPConnectionConfig(
                        host: "127.0.0.1",
                        port: Int(channelReceiver.localAddress!.port!)
                )
        )

        let metricLine = "test:1|ms"
        client.pushMetric(metricLine: metricLine)

        let expectedLine = metricLine + "\n"
        var buffer = channelSender.allocator.buffer(capacity: expectedLine.utf8.count)
        buffer.write(string: expectedLine)

        let reads = try channelReceiver.waitForDatagrams(count: 1)
        XCTAssertEqual(reads.count, 1)
        let envelope = reads.first!
        XCTAssertEqual(envelope.data, buffer)
    }

    static var allTests: [(String, (UDPStatsDClientTests) -> () throws -> Void)] {
        return [
            ("testClientShouldPushMetrics", testClientShouldPushMetrics),
        ]
    }
}
