import Foundation
import XCTest

@testable import SwiftBoxConfig

class EnvSourceTests: XCTestCase {
    func testEnvShouldBeParsedProperly() throws {
        let data = [
            "STRING": "string",
            "INT": "INT",
            "NESTED_TEST": "test",
            "NESTED_DEEP_ARRAY_0": "0",
            "NESTED_DEEP_ARRAY_1": "1",
        ]

        let result = try EnvSource(dataSource: data).getConfig()

        XCTAssertEqual(result["string"] as! String, "string")
        XCTAssertEqual(result["int"] as! String, "INT")
        XCTAssertEqual(result[keyPath: "nested.test"] as! String, "test")
        XCTAssertEqual(result[keyPath: "nested.deep.array"] as! Array, ["0", "1"])
    }

    func testPrefixShouldBeUsedToLimitEnvVariables() throws {
        let data = [
            "STRING": "string",
            "INT": "INT",
            "NESTED_TEST": "test",
            "NESTED_DEEP_ARRAY_0": "0",
            "NESTED_DEEP_ARRAY_1": "1",
        ]

        let result = try EnvSource(dataSource: data, prefix: "nested").getConfig()

        XCTAssertNil(result["string"])
        XCTAssertNil(result["int"])

        XCTAssertEqual(result["test"] as! String, "test")
        XCTAssertEqual(result[keyPath: "test"] as! String, "test")
        XCTAssertEqual(result[keyPath: "deep.array"] as! Array, ["0", "1"])
    }
}

class JSONSourceTests: XCTestCase {
    func testConfigShouldBeParsedProperly() throws {
        let data = """
        {"test": "test", "int": 1, "nil": null, "array":["1","2"], "arraynested": [{"test1":"test1", "test2": null}], "deep":{"test":"test"}}
        """

        let result = try JSONSource(dataSource: data.data(using: .utf8)!).getConfig()

        XCTAssertEqual(result["test"] as! String, "test")
        XCTAssertEqual(result["int"] as! Int, 1)
        XCTAssertNil(result["nil"]!)
        XCTAssertEqual(result["array"] as! [String], ["1", "2"])
        XCTAssertEqual(result[keyPath: "deep.test"] as! String, "test")
        XCTAssertEqual(result[keyPath: "arraynested.0.test1"] as! String, "test1")
        XCTAssertNil(result[keyPath: "arraynested.0.test2"])
    }
}

class DictionarySourceTests: XCTestCase {
    func testConfigShouldBeParsedProperly() throws {
        let data: [String: Any?] = [
            "test": "test",
            "nil": nil,
            "array": ["1", "2"],
            "arraynested": [
                [
                    "test1": "test1",
                    "test2": nil
                ]
            ],
            "deep": [
                "test": "test"
            ]
        ]

        let result = try DictionarySource(dataSource: data).getConfig()

        XCTAssertEqual(result[keyPath: "test"] as! String, "test")
        XCTAssertNil(result["nil"]!)
        XCTAssertEqual(result["array"] as! [String], ["1", "2"])
        XCTAssertEqual(result[keyPath: "deep.test"] as! String, "test")
        XCTAssertEqual(result[keyPath: "arraynested.0.test1"] as! String, "test1")
        XCTAssertNil(result[keyPath: "arraynested.0.test2"])
    }
}

class CommandLineSourceTests: XCTestCase {
    func testConfigShouldBeParsedProperly() throws {
        let data = [
            "--config:test=test",
            "--config:array.0=1",
            "--config:array.1=2",
            "--config:deep.test=test",
            "--port=0",
            "--test=11",
        ]

        let result = try CommandLineSource(dataSource: data).getConfig()

        XCTAssertEqual(result["test"] as! String, "test")
        XCTAssertEqual(result["array"] as! [String], ["1", "2"])
        XCTAssertEqual(result[keyPath: "deep.test"] as! String, "test")
    }

    func testCustomPrefixShouldUsedWhenPassed() throws {
        let data = [
            "--custom:test=test",
            "--custom:array.0=1",
            "--config:array.1=2",
            "--config:deep.test=test",
        ]

        let result = try CommandLineSource(dataSource: data, prefix: "--custom:").getConfig()

        XCTAssertEqual(result["test"] as! String, "test")
        XCTAssertEqual(result["array"] as! [String], ["1"])
        XCTAssertNil(result[keyPath: "deep.test"])
    }

    func testFilterByPrefixShouldInclude() throws {
        let data = [
            "--custom:test=test",
            "--custom:array.0=1",
            "--config:array.1=2",
            "--config:deep.test=test",
        ]

        let result = CommandLineSource.filterArguments(data)
        XCTAssertEqual(
                result,
                [
                    "--config:array.1=2",
                    "--config:deep.test=test",
                ]
        )
    }

    func testFilterByPrefixShouldExclude() throws {
        let data = [
            "--custom:test=test",
            "--custom:array.0=1",
            "--config:array.1=2",
            "--config:deep.test=test",
        ]

        let result = CommandLineSource.filterArguments(data, exclude: true)
        XCTAssertEqual(
                result,
                [
                    "--custom:test=test",
                    "--custom:array.0=1",
                ]
        )
    }

    func testFilterByCustomPrefix() throws {
        let data = [
            "--custom:test=test",
            "--custom:array.0=1",
            "--config:array.1=2",
            "--config:deep.test=test",
        ]

        let result = CommandLineSource.filterArguments(data, by: "--custom:")
        XCTAssertEqual(
                result,
                [
                    "--custom:test=test",
                    "--custom:array.0=1",
                ]
        )
    }

    func testDoubleEquationShouldBeParsed() throws {
        let data = [
            "--config:test.0=test",
            "--config:test.1=test=test=",
            "--config:test.2=test=test=test",
        ]

        let result = try CommandLineSource(dataSource: data).getConfig()

        XCTAssertEqual(result["test"] as! [String], ["test", "test=test=", "test=test=test"])
    }
}


// MARK: Manifest
extension EnvSourceTests {
    static let allTests = [
        ("testEnvShouldBeParsedProperly", testEnvShouldBeParsedProperly),
        ("testPrefixShouldBeUsedToLimitEnvVariables", testPrefixShouldBeUsedToLimitEnvVariables),
    ]
}

extension JSONSourceTests {
    static let allTests = [
        ("testConfigShouldBeParsedProperly", testConfigShouldBeParsedProperly),
    ]
}

extension DictionarySourceTests {
    static let allTests = [
        ("testConfigShouldBeParsedProperly", testConfigShouldBeParsedProperly),
    ]
}

extension CommandLineSourceTests {
    static let allTests = [
        ("testConfigShouldBeParsedProperly", testConfigShouldBeParsedProperly),
        ("testCustomPrefixShouldUsedWhenPassed", testCustomPrefixShouldUsedWhenPassed),
        ("testFilterByPrefixShouldInclude", testFilterByPrefixShouldInclude),
        ("testFilterByPrefixShouldExclude", testFilterByPrefixShouldExclude),
        ("testFilterByCustomPrefix", testFilterByCustomPrefix),
        ("testDoubleEquationShouldBeParsed", testDoubleEquationShouldBeParsed),
    ]
}

