import SwiftSyntax
import SwiftOperators
import StringWidth

class PowerAssertRewriter: SyntaxRewriter {
  private let expression: SyntaxProtocol
  private let sourceLocationConverter: SourceLocationConverter
  private let startColumn: Int

  init(macro: FreestandingMacroExpansionSyntax, expression: SyntaxProtocol) {
    let startLocation = macro.startLocation(converter: SourceLocationConverter(file: "", tree: macro))
    let endLocation = macro.macro.endLocation(converter: SourceLocationConverter(file: "", tree: macro))
    startColumn = endLocation.column! - startLocation.column!

    if let folded = try? OperatorTable.standardOperators.foldAll(expression) {
      self.expression = folded
    } else {
      self.expression = expression
    }

    self.sourceLocationConverter = SourceLocationConverter(file: "", tree: expression)
  }

  func rewrite() -> SyntaxProtocol {
    visit(expression.cast(SourceFileSyntax.self))
  }

  override func visit(_ node: ArrayExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: BooleanLiteralExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    return ExprSyntax(node)
  }

  override func visit(_ node: DictionaryExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: FloatLiteralExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: ForcedValueExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    let column: Int
    if let function = node.calledExpression.children(viewMode: .fixedUp).last {
      column = graphemeColumn(function)
    } else {
      column = graphemeColumn(node)
    }
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: IdentifierExprSyntax) -> ExprSyntax {
    if case .binaryOperator = node.identifier.tokenKind {
      return super.visit(node)
    }
    guard let parent = node.parent, parent.syntaxNodeType != FunctionCallExprSyntax.self else {
      return super.visit(node)
    }
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(
      ExprSyntax("\(visitedNode).self").with(\.leadingTrivia, visitedNode.leadingTrivia).with(\.trailingTrivia, visitedNode.trailingTrivia),
      column: column
    )
  }

  override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node.operatorOperand)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: KeyPathExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    guard let parent = node.parent, parent.syntaxNodeType != FunctionCallExprSyntax.self  else {
      return super.visit(node)
    }
    let column = graphemeColumn(node.name)
    let visitedNode = super.visit(node)
    if let optionalChainingExpr = findDescendants(syntaxType: OptionalChainingExprSyntax.self, node: node) {
      return ExprSyntax("\(apply(ExprSyntax(visitedNode), column: column))\(optionalChainingExpr.questionMark)")
    } else {
      return apply(ExprSyntax(visitedNode), column: column)
    }
  }

  override func visit(_ node: NilLiteralExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: OptionalChainingExprSyntax) -> ExprSyntax {
    let visitedNode = super.visit(node)
    return visitedNode
  }

  override func visit(_ node: PrefixOperatorExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: SequenceExprSyntax) -> ExprSyntax {
    guard let binaryOperatorExpr = findDescendants(syntaxType: BinaryOperatorExprSyntax.self, node: Syntax(node)) else  {
      return super.visit(node)
    }
    let column = graphemeColumn(binaryOperatorExpr)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: SubscriptExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node.rightBracket)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  override func visit(_ node: TupleExprSyntax) -> ExprSyntax {
    let column = graphemeColumn(node)
    let visitedNode = super.visit(node)
    return apply(ExprSyntax(visitedNode), column: column)
  }

  private func apply(_ node: ExprSyntax, column: Int) -> ExprSyntax {
    return FunctionCallExprSyntax(
      leadingTrivia: node.leadingTrivia,
      calledExpression: IdentifierExprSyntax(identifier: TokenSyntax(.identifier("$0.capture"), presence: .present)),
      leftParen: TokenSyntax.leftParenToken(),
      argumentList: TupleExprElementListSyntax([
        TupleExprElementSyntax(
          expression: node.with(\.leadingTrivia, []).with(\.trailingTrivia, []),
          trailingComma: TokenSyntax.commaToken(),
          trailingTrivia: Trivia.space
        ),
        TupleExprElementSyntax(
          label: TokenSyntax.identifier("column"),
          colon: TokenSyntax.colonToken().with(\.trailingTrivia, .space),
          expression: IntegerLiteralExprSyntax(digits: TokenSyntax.integerLiteral("\(column + startColumn)"))
        ),
      ]),
      rightParen: TokenSyntax.rightParenToken(),
      trailingTrivia: node.trailingTrivia
    )
    .cast(ExprSyntax.self)
  }

  private func findAncestors<T: SyntaxProtocol>(syntaxType: T.Type, node: SyntaxProtocol) -> T? {
    let node = node.parent
    var cur: Syntax? = node
    while let node = cur {
      if node.syntaxNodeType == syntaxType.self {
        return node.as(syntaxType)
      }
      cur = node.parent
    }
    return nil
  }

  private func findDescendants<T: SyntaxProtocol>(syntaxType: T.Type, node: SyntaxProtocol) -> T? {
    let children = node.children(viewMode: .fixedUp)
    for child in children {
      if child.syntaxNodeType == TokenSyntax.self {
        continue
      }
      if child.syntaxNodeType == syntaxType.self {
        return child.as(syntaxType)
      }
      if let found = findDescendants(syntaxType: syntaxType, node: child) {
        return found.as(syntaxType)
      }
    }
    return nil
  }

  private func graphemeColumn(_ node: SyntaxProtocol) -> Int {
    let startLocation = node.startLocation(converter: sourceLocationConverter)
    let column: Int
    if let graphemeClusters = String("\(expression)".utf8.prefix(startLocation.column!)) {
      column = stringWidth(graphemeClusters)
    } else {
      column = startLocation.column!
    }
    return column
  }
}