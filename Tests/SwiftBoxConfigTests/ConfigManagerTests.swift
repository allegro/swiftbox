import XCTest

@testable import SwiftBoxConfig

class ConfigManagerTests: XCTestCase {
    func testManagerShouldBootstrapFromEnv() throws {
        struct SampleConfig: Decodable, ConfigManager {
            var value: String? = nil
            public static var configuration: SampleConfig? = nil
        }

        try SampleConfig.bootstrap(from: [EnvSource(dataSource: [:])])
        XCTAssertNil(SampleConfig.global.value)
    }

    func testManagerShouldBootstrapFromJSON() throws {
        struct SampleConfig: Decodable, ConfigManager {
            var value: String?
            public static var configuration: SampleConfig? = nil
        }
        let jsonData = """
                       {"value":"test"}
                       """
        try SampleConfig.bootstrap(from: [JSONSource(dataSource: jsonData.data(using: .utf8)!)])
        XCTAssertEqual(SampleConfig.global.value!, "test")
    }

    func testManagerShouldMergeMultipleSources() throws {
        struct SampleConfig: Decodable, Equatable, ConfigManager {
            var string: String
            var int: Int
            var bool: Bool
            var nested: Nested

            public static var configuration: SampleConfig? = nil

            struct Nested: Decodable, Equatable {
                var array: [String]
                var int: Int
                var string: String
            }
        }

        let expectedValue = SampleConfig(
                string: "test",
                int: 10,
                bool: false,
                nested: SampleConfig.Nested(
                        array: ["test0", "test1"],
                        int: 11,
                        string: "string"
                )
        )
        let jsonData = """
                       {"string":"test","int":1}
                       """
        try SampleConfig.bootstrap(
                from: [
                    JSONSource(dataSource: jsonData.data(using: .utf8)!),
                    DictionarySource(dataSource: [
                        "int": 10,
                        "bool": true,
                        "nested": [
                            "string": "string",
                            "array": ["1", "2"]
                        ]
                    ]),
                    EnvSource(dataSource: [
                        "NESTED_INT": "11",
                        "NESTED_ARRAY_0": "test0",
                        "NESTED_ARRAY_1": "test1",
                        "BOOL": "0",
                    ])
                ]
        )
        XCTAssertEqual(SampleConfig.global, expectedValue)
    }

    func testManagerShouldFailWithoutBootstrap() throws {
        struct SampleConfig: Decodable, ConfigManager {
            var value: String? = nil
            public static var configuration: SampleConfig? = nil
        }

        XCTAssertThrowsError(try SampleConfig.getConfiguration()) { error in
            switch error as! ConfigManagerError {
            case .bootstrapRequired:
                break
            default:
                XCTFail("Wrong error thrown, expected ConfigManagerError.bootstrapRequired, got \(error)")
            }
        }
    }

    func testManagerShouldFailOnSecondBootstrap() throws {
        struct SampleConfig: Decodable, ConfigManager {
            var value: String? = nil
            public static var configuration: SampleConfig? = nil
        }

        try SampleConfig.bootstrap(from: [DictionarySource(dataSource: [:])])
        XCTAssertThrowsError(try SampleConfig.bootstrap(from: [DictionarySource(dataSource: [:])])) { error in
            switch error as! ConfigManagerError {
            case .alreadyBootstrapped:
                break
            default:
                XCTFail("Wrong error thrown, expected ConfigManagerError.alreadyBootstrapped, got \(error)")
            }
        }
    }
}

class ConfigSourcesBootstrapTests: XCTestCase {
    struct SampleConfig: Configuration, Equatable, ConfigManager {
        var test: String
        var int: Int
        var null: String?
        var missing: String?
        var array: [String?]
        var arraynested: [NestedConfig]
        var deep: NestedConfig

        public static var configuration: SampleConfig? = nil
    }
    struct NestedConfig: Configuration, Equatable {
        var test1: String
        var test2: String?
        var missing: String?
    }

    let expected = SampleConfig(
            test: "test",
            int: 1,
            null: nil,
            missing: nil,
            array: ["0", nil, "1"],
            arraynested: [
                NestedConfig(test1: "test1", test2: nil, missing: nil),
                NestedConfig(test1: "test1", test2: "test2", missing: nil)
            ],
            deep: NestedConfig(test1: "test1", test2: nil, missing: nil)
    )

    override func tearDown() {
        super.tearDown()
        SampleConfig.configuration = nil
    }

    func testDictSource() throws {
        let sources: [ConfigSource] = [
            DictionarySource(
                    dataSource: [
                        "test": "test",
                        "int": 1,
                        "null": nil,
                        "array": ["0", nil, "1"],
                        "arraynested": [
                            [
                                "test1": "test1",
                                "test2": nil
                            ],
                            [
                                "test1": "test1",
                                "test2": "test2"
                            ],
                        ],
                        "deep": [
                            "test1": "test1",
                            "test2": nil
                        ]
                    ] as [String: Any?]
            ),
        ]

        try SampleConfig.bootstrap(from: sources)
        XCTAssertEqual(SampleConfig.global, expected)
    }


    func testJSONSource() throws {
        let sources: [ConfigSource] = [
            JSONSource(
                    dataSource: """
                    {
                      "test": "test",
                      "int": 1,
                      "null": null,
                      "array": ["0", null, "1"],
                      "arraynested": [
                        {
                          "test1": "test1",
                          "test2": null
                        },
                        {
                          "test1": "test1",
                          "test2": "test2"
                        }
                      ],
                      "deep": {
                        "test1": "test1",
                        "test2": null
                      }
                    }
                    """.data(using: .utf8)!
            ),
        ]

        try SampleConfig.bootstrap(from: sources)
        XCTAssertEqual(SampleConfig.global, expected)
    }

    func testEnvSource() throws {
        let sources: [ConfigSource] = [
            EnvSource(
                    dataSource: [
                        "TEST": "test",
                        "INT": "1",
                        "ARRAY_0": "0",
                        "ARRAY_1": "null",
                        "ARRAY_2": "1",
                        "ARRAYNESTED_0_TEST1": "test1",
                        "ARRAYNESTED_0_TEST2": "null",
                        "ARRAYNESTED_1_TEST1": "test1",
                        "ARRAYNESTED_1_TEST2": "test2",
                        "DEEP_TEST1": "test1",
                        "DEEP_TEST2": "null",
                    ]
            ),
        ]

        try SampleConfig.bootstrap(from: sources)
        XCTAssertEqual(SampleConfig.global, expected)
    }

    func testCommandLineSource() throws {
        let sources: [ConfigSource] = [
            CommandLineSource(
                    dataSource: [
                        "--config:test=test",
                        "--config:int=1",
                        "--config:array.0=0",
                        "--config:array.1=null",
                        "--config:array.2=1",
                        "--config:arraynested.0.test1=test1",
                        "--config:arraynested.0.test2=null",
                        "--config:arraynested.1.test1=test1",
                        "--config:arraynested.1.test2=test2",
                        "--config:deep.test1=test1",
                        "--config:deep.test2=null",
                    ]
            ),
        ]

        try SampleConfig.bootstrap(from: sources)
        XCTAssertEqual(SampleConfig.global, expected)
    }
}


extension ConfigManagerTests {
    static let allTests = [
        ("testManagerShouldBootstrapFromEnv", testManagerShouldBootstrapFromEnv),
        ("testManagerShouldBootstrapFromJSON", testManagerShouldBootstrapFromJSON),
        ("testManagerShouldMergeMultipleSources", testManagerShouldMergeMultipleSources),
        ("testManagerShouldFailWithoutBootstrap", testManagerShouldFailWithoutBootstrap),
        ("testManagerShouldFailOnSecondBootstrap", testManagerShouldFailOnSecondBootstrap),
    ]
}


extension ConfigSourcesBootstrapTests {
    static let allTests = [
        ("testDictSource", testDictSource),
        ("testJSONSource", testJSONSource),
        ("testEnvSource", testEnvSource),
        ("testCommandLineSource", testCommandLineSource),
    ]
}
