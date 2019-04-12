import Foundation
import XCTest

@testable import SwiftBoxConfig

struct TestConfiguration: Decodable, Equatable {
    let nested: NestedConfiguration
    let string: String
    let int: Int
    let nullableString: String?

    struct NestedConfiguration: Decodable, Equatable {
        let null: String?
        let nullableInt: Int?
        let arrayString: [String]
        let deep: DeepNestedConfiguration

        enum CodingKeys: String, CodingKey {
            case null, nullableInt, deep
            case arrayString = "arraystring"
        }

        struct DeepNestedConfiguration: Decodable, Equatable {
            let bool1: Bool
            let bool2: Bool
            let bool3: Bool?
            let bool4: Bool?
        }
    }
}

class ConfigurationParsingTests: XCTestCase {

    func testConfigShouldParseProperly() throws {
        let expectedConfig = TestConfiguration(
                nested: TestConfiguration.NestedConfiguration(
                        null: nil,
                        nullableInt: nil,
                        arrayString: ["arraystring0", "arraystring1"],
                        deep: TestConfiguration.NestedConfiguration.DeepNestedConfiguration(
                                bool1: true,
                                bool2: false,
                                bool3: nil,
                                bool4: true
                        )
                ),
                string: "string",
                int: 111,
                nullableString: "1"
        )

        let data: [String : Any] = [
            "string": "string",
            "int": 111,
            "nullableString": "1",
            "nested": [
                "null": nil,
                "nullableint": nil,
                "arraystring": ["arraystring0", "arraystring1"],
                "deep": [
                    "bool1": true,
                    "bool2": false,
                    "bool3": nil,
                    "bool4": true,
                ]
            ],
        ]

        let config = try TestConfiguration(from: DictionaryDecoder(codingPath: [], storage: data))
        XCTAssertEqual(config, expectedConfig)
    }

    func testNilAndMissingValuesShouldBeHandledProperly() throws {
        struct SampleConf: Decodable, Equatable {
            let int: Int?
            let int2: Int?
            let int3: Int?
        }

        let expectedConfig = SampleConf(
                int: 11,
                int2: nil,
                int3: nil
        )

        let data: [String: Any?] = [
            "int": 11,
            "int2": nil,
        ]

        let config = try SampleConf(from: DictionaryDecoder(codingPath: [], storage: data))
        XCTAssertEqual(config, expectedConfig)
    }

    func testOptionalsShouldBeHandledProperly() throws {
        struct NullableConfig: Decodable, Equatable {
            var int: Int?
            var string: String?
            var bool: Bool?
            var nullarray: [String]?
            var arrayofnulls: [String?]
            var nested: Nested?

            struct Nested: Decodable, Equatable {
                var nested: String?
            }
        }

        let data: [String : Any] = [:]
        let config = try NullableConfig(from: DictionaryDecoder(codingPath: [], storage: data))
        XCTAssertEqual(
                config,
                NullableConfig(int: nil, string: nil, bool: nil, nullarray: nil, arrayofnulls: [], nested: nil)
        )
    }

    func testValuesShouldBeCoerced() throws {
        struct CoerceConfig: Decodable, Equatable {
            var int: Int
            var string: String
            var bool: Bool

            var intarray: [Int]
            var stringarray: [String]
            var boolarray: [Bool]

            var nested: Nested

            struct Nested: Decodable, Equatable {
                var int: Int
                var string: String
                var bool: Bool
            }
        }

        let data: [String : Any] = [
            "int": "1",
            "string": "1",
            "bool": "1",
            "intarray": ["1", "2", "-1"],
            "stringarray": ["1", "2", "-1"],
            "boolarray": ["1", "0", "true", "false"],
            "nested": [
                "int": "0",
                "string": "0",
                "bool": "0",
            ],
        ]

        let config = try CoerceConfig(from: DictionaryDecoder(codingPath: [], storage: data))
        XCTAssertEqual(
                config,
                CoerceConfig(
                        int: 1,
                        string: "1",
                        bool: true,
                        intarray: [1, 2, -1],
                        stringarray: ["1", "2", "-1"],
                        boolarray: [true, false, true, false],
                        nested: CoerceConfig.Nested(
                                int: 0,
                                string: "0",
                                bool: false
                        )
                )
        )
    }

    func testNumericValuesShouldBeParsedToRightType() throws {
        struct NumericConfig: Decodable, Equatable {
            var double: Double
            var float: Float
        }

        let data: [String : Any] = [
            "double": "2.3",
            "float": "4",
        ]

        let config = try NumericConfig(from: DictionaryDecoder(codingPath: [], storage: data))
        XCTAssertEqual(
                config,
                NumericConfig(
                        double: 2.3,
                        float: 4
                )
        )
    }

    func testBoolCastShouldRaiseErrorOnWrongValue() throws {
        struct BoolConfig: Decodable, Equatable {
            var bool: Bool
        }

        let data: [String : Any] = [
            "bool": "3",
        ]

        XCTAssertThrowsError(try BoolConfig(from: DictionaryDecoder(codingPath: [], storage: data))) { error in
            XCTAssert(error is DecoderError)
            switch error as! DecoderError {
            case .castError(let message):
                XCTAssert(message.contains("Unknown value"))
            default:
                XCTFail("Exception was not raised")
            }
        }
    }
}

// MARK: Manifest
extension ConfigurationParsingTests {
    static let allTests = [
        ("testConfigShouldParseProperly", testConfigShouldParseProperly),
        ("testNilAndMissingValuesShouldBeHandledProperly", testNilAndMissingValuesShouldBeHandledProperly),
        ("testOptionalsShouldBeHandledProperly", testOptionalsShouldBeHandledProperly),
        ("testValuesShouldBeCoerced", testValuesShouldBeCoerced),
        ("testNumericValuesShouldBeParsedToRightType", testNumericValuesShouldBeParsedToRightType),
        ("testBoolCastShouldRaiseErrorOnWrongValue", testBoolCastShouldRaiseErrorOnWrongValue),
    ]
}
