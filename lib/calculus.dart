import 'package:calculator/operation.dart';
import 'package:calculator/sign.dart';
import 'package:calculator/validator.dart';

final parenthesis = RegExp(r'[)(]');
final parenthesisContent = RegExp(r'\(([^\)(]+)\)');

class Calculus {
  const Calculus._(this.input);

  factory Calculus._withParenthesis(String input, {bool shouldCheckPriority = false}) {
    var values = input;

    Calculus getCalculus(String input) {
      if (shouldCheckPriority) {
        return Calculus._withPriority(input);
      } else {
        return Calculus._(input);
      }
    }

    while (values.contains(parenthesisContent)) {
      values = values.replaceParenthesis(
        (newInput) => getCalculus(newInput).result.toString(),
      );
    }

    return getCalculus(values);
  }

  factory Calculus._withPriority(String input) {
    var newInput = input;
    var previousIndex = 0;
    int? actualIndex;
    int? lastIndex;

    var index = 0;
    while (index < newInput.length) {
      final symbol = newInput[index];

      final isSign = _isSign(symbol);

      if (isSign) {
        if (Sign.fromSymbol(symbol).hasPriority) {
          actualIndex = index;

          if (newInput[index + 1] == Sign.plus.symbol || newInput[index + 1] == Sign.minus.symbol) {
            index++;
          }
        } else {
          if (actualIndex == null) {
            previousIndex = index;
          } else {
            lastIndex = index;
          }
        }
      }

      if (lastIndex != null) {
        newInput = '${newInput.substring(0, previousIndex + 1)}(${newInput.substring(previousIndex + 1)}';
        newInput = '${newInput.substring(0, lastIndex + 1)})${newInput.substring(lastIndex + 1)}';

        previousIndex = lastIndex;
        actualIndex = null;
        lastIndex = null;
      }

      if (index == newInput.length - 1 && actualIndex != null) {
        newInput = '${newInput.substring(0, previousIndex + 1)}(${newInput.substring(previousIndex + 1)}';
        newInput = newInput.padRight(newInput.length + 1, ')');
        actualIndex = null;
      }

      index++;
    }

    if (input != newInput) {
      return Calculus._withParenthesis(newInput, shouldCheckPriority: false);
    } else {
      return Calculus._(newInput);
    }
  }

  factory Calculus(String input) {
    final value = input.trim().clearSignAmbiguity();

    if (value.contains(parenthesis)) {
      Validator.checkParenthesis(value);

      return Calculus._withParenthesis(value, shouldCheckPriority: true);
    } else {
      return Calculus._withPriority(value);
    }
  }

  final String input;

  num get result {
    num result = 0;
    String newInput = input.clearSignAmbiguity();

    int? firstSignIndex = _getFirstSignIndex(newInput);
    int? nextSignIndex = _getNextSignIndex(newInput, firstSignIndex);

    while (firstSignIndex != null) {
      final sign = Sign.fromSymbol(newInput[firstSignIndex]);
      final smallInput = nextSignIndex != null ? newInput.substring(0, nextSignIndex) : newInput;

      result = selectOperation(sign, smallInput).result;
      newInput = newInput.replaceRange(0, nextSignIndex, '$result');

      if (nextSignIndex != null) {
        firstSignIndex = _getFirstSignIndex(newInput);
        nextSignIndex = _getNextSignIndex(newInput, firstSignIndex);
      } else {
        firstSignIndex = null;
      }
    }

    return result;
  }

  int? _getFirstSignIndex(String input) {
    int startIndex = 0;

    if (input[startIndex] == Sign.minus.symbol) {
      startIndex++;
    }

    for (var index = startIndex; index < input.length; index++) {
      if (_isSign(input[index])) {
        return index;
      }
    }

    return null;
  }

  int? _getNextSignIndex(String input, [int? firstIndex]) {
    if (firstIndex != null) {
      int startIndex = firstIndex + 1;

      if (input[startIndex] == Sign.plus.symbol || input[startIndex] == Sign.minus.symbol) {
        startIndex++;
      }

      for (var index = startIndex; index < input.length; index++) {
        if (_isSign(input[index])) {
          return index;
        }
      }
    }

    return null;
  }

  static bool _isSign(String symbol) => Sign.values.map((e) => e.symbol).contains(symbol);

  Operation selectOperation(Sign sign, String input) {
    switch (sign) {
      case Sign.plus:
        return Addition(input);
      case Sign.minus:
        return Subtraction(input);
      case Sign.times:
        return Multiplication(input);
      case Sign.divide:
        return Division(input);
    }
  }
}

extension on String {
  String replaceParenthesis([String Function(String)? computation]) {
    return replaceAllMapped(parenthesisContent, (match) {
      final newInput = match[0]!.replaceAll(parenthesis, '');

      return computation?.call(newInput) ?? newInput;
    });
  }

  String clearSignAmbiguity() {
    String newInput = this;

    var index = 1;
    while (index < newInput.length) {
      final previousSign = newInput[index - 1];
      final actualSign = newInput[index];

      if ((previousSign == '+' && actualSign == '+') || (previousSign == '-' && actualSign == '+')) {
        newInput = '${newInput.substring(0, index)}${newInput.substring(index + 1)}';

        index--;
      } else if (previousSign == '+' && actualSign == '-') {
        newInput = '${newInput.substring(0, index - 1)}${newInput.substring(index)}';
        index--;
      } else if (previousSign == '-' && actualSign == '-') {
        newInput = '${newInput.substring(0, index - 1)}+${newInput.substring(index + 1)}';
        index--;
      }

      index++;
    }

    return newInput;
  }
}
