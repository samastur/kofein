import Testing
@testable import KofeinCore

@Test func defaultOptionsProduceNoArguments() {
    #expect(CaffeinateOptions().arguments.isEmpty)
}
