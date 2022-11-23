import XCTest
@testable import CustardExpressionEvaluator

final class CustardExpressionEvaluatorTests: XCTestCase {
    func testTokenizer() throws {
        let tokenizer = CustardExpressionTokenizer()
        do {
            let result = tokenizer.tokenize(expression: "not((state_a == 'normal') and state_b)")
            XCTAssertEqual(result, [.function(.not), .leftParen, .leftParen, .variable("state_a"), .operator(.equal), .stringLiteral("normal"), .rightParen, .operator(.and), .variable("state_b"), .rightParen])
        }
        do {
            let result = tokenizer.tokenize(expression: "true")
            XCTAssertEqual(result, [.boolLiteral(true)])
        }
        do {
            let result = tokenizer.tokenize(expression: "((state_a and 'normal' != state_c) xor state_b)")
            XCTAssertEqual(result, [.leftParen, .leftParen, .variable("state_a"), .operator(.and), .stringLiteral("normal"), .operator(.notEqual), .variable("state_c"), .rightParen, .operator(.xor), .variable("state_b"), .rightParen])
        }

    }

    func testCompiler() throws {
        let tokenizer = CustardExpressionTokenizer()
        let compiler = CustardExpressionCompiler()
        do {
            let tokens = tokenizer.tokenize(expression: "true")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .boolLiteral(true))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "''value''")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .stringLiteral("'value'"))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "state_a")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .variable("state_a"))
        }
        do {
            let tokens = tokenizer.tokenize(expression: " true ")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .boolLiteral(true))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "((((state_a))))")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .variable("state_a"))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "not(state_a and true)")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .function(.not, .operator(.and, .variable("state_a"), .boolLiteral(true))))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "not((state_a == 'normal') and state_b)")
            let result = try compiler.compile(tokens: tokens)
            XCTAssertEqual(result, .function(.not, .operator(.and, .operator(.equal, .variable("state_a"), .stringLiteral("normal")), .variable("state_b"))))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "state_a and 'normal' != state_c")
            XCTAssertThrowsError(try compiler.compile(tokens: tokens))
        }
    }

    struct EvaluatorContext: CustardExpressionEvaluatorContext {
        var initialValues: [String: ExpressionValue]
        func getInitialValue(for key: String) -> ExpressionValue? {
            return initialValues[key]
        }

        func getValue(for key: String) -> ExpressionValue? {
            return nil
        }
    }

    func testEvaluator() throws {
        let tokenizer = CustardExpressionTokenizer()
        let compiler = CustardExpressionCompiler()
        do {
            let evaluator = CustardExpressionEvaluator(context: EvaluatorContext(initialValues: [:]))
            let tokens = tokenizer.tokenize(expression: "true")
            let compiledExpression = try compiler.compile(tokens: tokens)
            XCTAssertEqual(try evaluator.evaluate(compiledExpression: compiledExpression), .bool(true))
        }
        do {
            let evaluator = CustardExpressionEvaluator(context: EvaluatorContext(initialValues: ["state_a": .string("normal"), "state_b": .bool(true)]))
            let tokens = tokenizer.tokenize(expression: "not((state_a == 'normal') and state_b)")
            let compiledExpression = try compiler.compile(tokens: tokens)
            XCTAssertEqual(try evaluator.evaluate(compiledExpression: compiledExpression), .bool(false))
        }
    }
}
