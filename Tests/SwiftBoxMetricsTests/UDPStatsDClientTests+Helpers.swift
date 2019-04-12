import Foundation
import XCTest

import NIO

/// Copied from /NIOTests/DatagramChannelTests.swift
extension Channel {
    func waitForDatagrams(count: Int) throws -> [AddressedEnvelope<ByteBuffer>] {
        return try self.pipeline.context(name: "ByteReadRecorder").flatMap { context in
            if let future = (context.handler as? DatagramReadRecorder<ByteBuffer>)?.notifyForDatagrams(count) {
                return future
            }

            XCTFail("Could not wait for reads")
            return self.eventLoop.newSucceededFuture(result: [] as [AddressedEnvelope<ByteBuffer>])
        }.wait()
    }
}

/// A class that records datagrams received and forwards them on.
///
/// Used extensively in tests to validate messaging expectations.
class DatagramReadRecorder<DataType>: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<DataType>
    typealias InboundOut = AddressedEnvelope<DataType>

    enum State {
        case fresh
        case registered
        case active
    }

    var reads: [AddressedEnvelope<DataType>] = []
    var loop: EventLoop? = nil
    var state: State = .fresh

    var readWaiters: [Int: EventLoopPromise<[AddressedEnvelope<DataType>]>] = [:]

    func channelRegistered(ctx: ChannelHandlerContext) {
        XCTAssertEqual(.fresh, self.state)
        self.state = .registered
        self.loop = ctx.eventLoop
    }

    func channelActive(ctx: ChannelHandlerContext) {
        XCTAssertEqual(.registered, self.state)
        self.state = .active
    }

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        XCTAssertEqual(.active, self.state)
        let data = self.unwrapInboundIn(data)
        reads.append(data)

        if let promise = readWaiters.removeValue(forKey: reads.count) {
            promise.succeed(result: reads)
        }

        ctx.fireChannelRead(self.wrapInboundOut(data))
    }

    func notifyForDatagrams(_ count: Int) -> EventLoopFuture<[AddressedEnvelope<DataType>]> {
        guard reads.count < count else {
            return loop!.newSucceededFuture(result: .init(reads.prefix(count)))
        }

        readWaiters[count] = loop!.newPromise()
        return readWaiters[count]!.futureResult
    }
}