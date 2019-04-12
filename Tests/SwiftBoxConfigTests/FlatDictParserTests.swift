import Foundation
import XCTest

@testable import SwiftBoxConfig

class FlatDictParserTests: XCTestCase {
    func testParseFromEnv() throws {
        let data = [
            "STRING": "string",
            "INT": "111",
            "NULL": "null",
            "NESTED_ARRAYSTRING_0": "arraystring0",
            "NESTED_ARRAYSTRING_1": "arraystring1",
            "NESTED_ARRAYSTRING_2": "null",
            "NESTED_DEEP_BOOL1": "true",
            "NESTED_DEEP_BOOL2": "1",
            "NESTED_DEEP_BOOL3": "0",
            "NESTED_DEEP_BOOL4": "false",

            "NESTED_ARRAYOBJ_0_TEST1": "test1",
            "NESTED_ARRAYOBJ_0_TEST2": "test2",
            "NESTED_ARRAYOBJ_1_TEST1": "test3",
            "NESTED_ARRAYOBJ_1_TEST2": "test4",
            "NESTED_ARRAYOBJ_1_TEST3": "null",

            "OTHER_ARGUMENT": "0",
        ]

        let result = try FlatDictConfigParser(data: data, separator: "_").decode()

        XCTAssertEqual(result["int"] as! String, "111")
        XCTAssertEqual(result["string"] as! String, "string")
        XCTAssertNil(result["null"]!)
        XCTAssertEqual((result["other"] as! Dictionary<String, String>)["argument"], "0")
        XCTAssertEqual((result["other"] as! Dictionary<String, String>)["argument"], "0")
        XCTAssertEqual(
                (result["nested"] as! Dictionary<String, Any>)["arraystring"] as! Array<String?>,
                ["arraystring0", "arraystring1", nil]
        )
        XCTAssertEqual(
                (result["nested"] as! Dictionary<String, Any>)["deep"] as! Dictionary<String, String>,
                [
                    "bool1": "true",
                    "bool2": "1",
                    "bool3": "0",
                    "bool4": "false",
                ]
        )
        XCTAssertEqual(
                (result["nested"] as! Dictionary<String, Any>)["arrayobj"] as! Array<Dictionary<String, String?>>,
                [
                    [
                        "test1": "test1",
                        "test2": "test2",
                    ],
                    [
                        "test1": "test3",
                        "test2": "test4",
                        "test3": nil,
                    ]
                ]
        )
    }

    func testArrayMissingIndexesShouldBeFilledWithNil() throws {
        let data = [
            "ARRAYSTRING_0": "0",
            "ARRAYSTRING_1": "1",
            "ARRAYSTRING_2": "null",
            "ARRAYSTRING_5": "5"
        ]

        let result = try FlatDictConfigParser(data: data, separator: "_").decode()
        XCTAssertEqual(result["arraystring"] as! Array<String?>, ["0", "1", nil, nil, nil, "5"])
    }

    func testArrayMissingIndexesInNestedTypeShouldBeFilledWithNil() throws {
        let data = [
            "ARRAYSTRING_0_TEST": "0",
            "ARRAYSTRING_1_TEST": "1",
            "ARRAYSTRING_3_TEST": "3"
        ]

        let result = try FlatDictConfigParser(data: data, separator: "_").decode()
        XCTAssertEqual(
                result["arraystring"] as! Array<Dictionary<String, String>?>,
                [["test": "0"], ["test": "1"], nil, ["test": "3"]]
        )
    }

    func testOverrideOfComplexTypeValueShouldFail() throws {
        let data = [
            "ARRAYSTRING_0": "0",
            "ARRAYSTRING_1": "1",
            "ARRAYSTRING_5": "5",

            "ARRAYSTRING": "test"
        ]

        XCTAssertThrowsError(try FlatDictConfigParser(data: data, separator: "_").decode()) { error in
            XCTAssert(error is EnvParseError)
            XCTAssert((error as! EnvParseError).message.contains("Misconfiguration error"))
        }
    }
}

// MARK: Manifest
extension FlatDictParserTests {
    static let allTests = [
        ("testParseFromEnv", testParseFromEnv),
        ("testArrayMissingIndexesShouldBeFilledWithNil", testArrayMissingIndexesShouldBeFilledWithNil),
        ("testArrayMissingIndexesInNestedTypeShouldBeFilledWithNil", testArrayMissingIndexesInNestedTypeShouldBeFilledWithNil),
        ("testOverrideOfComplexTypeValueShouldFail", testOverrideOfComplexTypeValueShouldFail),
    ]
}

