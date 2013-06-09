// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fancy_syntax.parser;

import 'tokenizer.dart';
import 'visitor.dart';
import 'expression.dart';

const _UNARY_OPERATORS = const ['+', '-', '!'];

class Parser {
  final Tokenizer _tokenizer;
  List<Token> _tokens;
  Iterator _iterator;
  Token _token;

  Parser(String input) : _tokenizer = new Tokenizer(input);

  Expression parse() {
    _tokens = _tokenizer.tokenize();
    _iterator = _tokens.iterator;
    _advance();
    return _parseExpression();
  }

  _advance([int kind, String value]) {
    if ((kind != null && _token.kind != kind)
        || (value != null && _token.value != value)) {
      throw new ParseException("Expected $value");
    }
    _token = _iterator.moveNext() ? _iterator.current : null;
  }

  Expression _parseExpression() {
    var expr = _parseUnary();
    return (expr == null) ? null : _parsePrecedence(expr, 0);
  }

  // _parsePrecedence and _parseBinary implement the precedence climbing
  // algorithm as described in:
  // http://en.wikipedia.org/wiki/Operator-precedence_parser#Precedence_climbing_method
  Expression _parsePrecedence(Expression left, int precedence) {
    assert(left != null);
    while (_token != null) {
      if (_token.kind == GROUPER_TOKEN) {
        if (_token.value == '(') {
          var args = _parseArguments();
          left = new Invoke(left, null, args);
        } else if (_token.value == '[') {
          var indexExpr = _parseIndex();
          var args = indexExpr == null ? [] : [indexExpr];
          left = new Invoke(left, '[]', args);
        } else {
          break;
        }
      } else if (_token.kind == DOT_TOKEN) {
        _advance();
        var right = _parseUnary();
        left = _makeInvoke(left, right);
      } else if (_token.kind == OPERATOR_TOKEN
          && _token.precedence >= precedence) {
        left = _parseBinary(left);
      } else {
        break;
      }
    }
    return left;
  }

  Invoke _makeInvoke(left, right) {
    if (right is Identifier) {
      return new Invoke(left, right.value);
    } else if (right is Invoke && right.receiver is Identifier) {
      Identifier method = right.receiver;
      return new Invoke(left, method.value, right.arguments);
    } else {
      throw new ParseException("expected identifier: $right");
    }
  }

  Expression _parseBinary(left) {
    var op = _token;
    _advance();
    var right = _parseUnary();
    while (_token != null
        && (_token.kind == OPERATOR_TOKEN
        || _token.kind == DOT_TOKEN
        || _token.kind == GROUPER_TOKEN)
        && _token.precedence > op.precedence) {
      right = _parsePrecedence(right, _token.precedence);
    }
    return new BinaryOperator(left, op.value, right);
  }

  Expression _parseUnary() {
    if (_token.kind == OPERATOR_TOKEN) {
      var value = _token.value;
      if (value == '+' || value == '-') {
        _advance();
        if (_token.kind == INTEGER_TOKEN) {
          return _parseInteger(value);
        } else if (_token.kind == DECIMAL_TOKEN) {
          return _parseDecimal(value);
        } else {
          var expr = _parsePrecedence(_parsePrimary(), POSTFIX_PRECEDENCE);
          return new UnaryOperator(value, expr);
        }
      } else if (value == '!') {
        _advance();
        var expr = _parsePrecedence(_parsePrimary(), POSTFIX_PRECEDENCE);
        return new UnaryOperator(value, expr);
      }
    }
    return _parsePrimary();
  }

  Expression _parsePrimary() {
    var kind = _token.kind;
    switch (kind) {
      case IDENTIFIER_TOKEN:
        return _parseInvokeOrIdentifier();
        break;
      case STRING_TOKEN:
        return _parseString();
        break;
      case INTEGER_TOKEN:
        return _parseInteger();
        break;
      case DECIMAL_TOKEN:
        return _parseDecimal();
        break;
      case GROUPER_TOKEN:
        if (_token.value == '(') {
          return _parseParenthesized();
        }
        return null;
        break;
      default:
        return null;
    }
  }

  Expression _parseInvokeOrIdentifier() {
    if (_token.value == 'true') {
      _advance();
      return new Literal<bool>(true);
    }
    if (_token.value == 'false') {
      _advance();
      return new Literal<bool>(false);
    }
    var identifier = _parseIdentifier();
    var args = _parseArguments();
    if (args == null) {
      return identifier;
    } else {
      return new Invoke(identifier, null, args);
    }
  }

  Expression _parseInvoke() {
    var identifier = _parseIdentifier();
    var args = _parseArguments();
    return new Invoke(null, identifier, args);
  }

  Identifier _parseIdentifier() {
    if (_token.kind != IDENTIFIER_TOKEN) {
      throw new ParseException("expected identifier: $_token");
    }
    var value = _token.value;
    _advance();
    return new Identifier(value);
  }

  List<Expression> _parseArguments() {
    if (_token != null && _token.kind == GROUPER_TOKEN && _token.value == '(') {
      var args = [];
      do {
        _advance();
        if (_token.kind == GROUPER_TOKEN && _token.value == ')') {
          _advance();
          break;
        }
        var expr = _parseExpression();
        args.add(expr);
      } while(_token != null && _token.value == ',');
      return args;
    }
    return null;
  }

  Expression _parseIndex() {
    if (_token != null && _token.kind == GROUPER_TOKEN && _token.value == '[') {
      _advance();
      var expr = _parseExpression();
      _advance(GROUPER_TOKEN, ']');
      return expr;
    }
    return null;
  }

  Expression _parseParenthesized() {
    _advance();
    var expr = _parseExpression();
    _advance(GROUPER_TOKEN, ')');
    return new ParenthesizedExpression(expr);
  }

  Expression _parseString() {
    var value = new Literal<String>(_token.value);
    _advance();
    return value;
  }

  Expression _parseInteger([String prefix = '']) {
    var value = new Literal<int>(int.parse('$prefix${_token.value}'));
    _advance();
    return value;
  }

  Expression _parseDecimal([String prefix = '']) {
    var value = new Literal<double>(double.parse('$prefix${_token.value}'));
    _advance();
    return value;
  }

}
