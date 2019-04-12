import Foundation
import XCTest

@testable import NIO
@testable import SwiftBoxMetrics

class TCPStatsDClientTests: XCTestCase {

    func testClientShouldPushMetrics() throws {
        let eventLoop = EmbeddedEventLoop()
        let channel = EmbeddedChannel(loop: eventLoop)
        let client = TCPStatsDClient(
                config: TCPConnectionConfig(
                        host: "localhost",
                        connectionFactory: { config in
                            return EventLoopFuture(
                                    eventLoop: eventLoop,
                                    result: channel,
                                    file: #file,
                                    line: #line
                            )
                        }
                )
        )

        client.pushMetric(metricLine: "test:1|ms")

        if case .some(.byteBuffer(let buffer)) = channel.readOutbound() {
            let data = buffer.getString(at: 0, length: buffer.readableBytes)!
            XCTAssertEqual(data, "test:1|ms\n")
        } else {
            XCTFail("Got invalid type from channel data")
        }
    }

    class FailingHandler: _ChannelOutboundHandler {
        func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
            promise?.fail(error: ChannelError.ioOnClosedChannel)
        }
    }

    func testClientShouldRetryWhenChannelError() throws {
        let eventLoop = EmbeddedEventLoop()
        let channel = EmbeddedChannel(handler: FailingHandler(), loop: eventLoop)
        var countChannelInitialization = 0

        let client = TCPStatsDClient(
                config: TCPConnectionConfig(
                        host: "localhost",
                        connectionFactory: { config in
                            countChannelInitialization += 1
                            return EventLoopFuture(
                                    eventLoop: eventLoop,
                                    result: channel,
                                    file: #file,
                                    line: #line
                            )
                        }
                )
        )

        client.pushMetric(metricLine: "test:1|ms")

        // Channel should be reinitialized up to 5 times on failure
        XCTAssertEqual(countChannelInitialization, 6)
    }

    func testClientShouldRetryWhenConnectionError() throws {
        let eventLoop = EmbeddedEventLoop()
        var countChannelInitialization = 0

        let client = TCPStatsDClient(
                config: TCPConnectionConfig(
                        host: "localhost",
                        connectionTimeout: TimeAmount.milliseconds(100),
                        connectionFactory: { config in
                            countChannelInitialization += 1
                            return EventLoopFuture(
                                    eventLoop: eventLoop,
                                    error: ChannelError.ioOnClosedChannel,
                                    file: #file,
                                    line: #line
                            )
                        }
                )
        )

        client.pushMetric(metricLine: "test:1|ms")

        // Channel should be reinitialized up to 5 times on failure
        XCTAssertEqual(countChannelInitialization, 6)
    }

    func testClientDefaultFactoryShouldInitializeProperly() throws {
        let client = TCPStatsDClient(
                config: TCPConnectionConfig(
                        host: "localhost",
                        port: 9999
                )
        )

        XCTAssertThrowsError(try client.getConnection().wait(), "Wrong exception thrown", { error in
            XCTAssert(error is ChannelError)
        })
    }

    static var allTests: [(String, (TCPStatsDClientTests) -> () throws -> Void)] {
        return [
            ("testClientShouldPushMetrics", testClientShouldPushMetrics),
            ("testClientShouldRetryWhenChannelError", testClientShouldRetryWhenChannelError),
            ("testClientShouldRetryWhenConnectionError", testClientShouldRetryWhenConnectionError),
            ("testClientDefaultFactoryShouldInitializeProperly", testClientDefaultFactoryShouldInitializeProperly),
        ]
    }
}
