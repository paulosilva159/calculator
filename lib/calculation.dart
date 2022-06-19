import 'package:calculator/operation.dart';
import 'package:calculator/sign.dart';
import 'package:calculator/validator.dart';

class CalculationImpl extends Calculation {
  @override
  num compute(String input) {
    var newInput = input.trim().clearSignAmbiguity();

    if (newInput.contains(_StringPattern.parenthesis)) {
      Validator.checkParenthesis(newInput);

      return _ParenthesisCalculation().compute(newInput);
    } else if (input.contains('*') || newInput.contains('/')) {
      return _PriorityCalculation().compute(newInput);
    } else {
      return super.compute(newInput);
    }
  }
}

class _ParenthesisCalculation extends Calculation {
  @override
  num compute(String input) {
    var newInput = input;

    num getResult(String input) {
      if (input.contains('*') || newInput.contains('/')) {
        return _PriorityCalculation().compute(input);
      } else {
        return super.compute(input);
      }
    }

    while (newInput.contains(_StringPattern.parenthesisContent)) {
      newInput = newInput.clearSignAmbiguity().replaceParenthesis(
            (newInput) => getResult(newInput).toString(),
          );
    }

    return getResult(newInput);
  }
}

class _PriorityCalculation extends Calculation {
  @override
  num compute(String input) {
    var newInput = input;
    var previousSignIndex = 0;
    int? actualSignIndex;
    int? lastSignIndex;

    var index = 0;
    while (index < newInput.length) {
      final symbol = newInput[index];

      if (symbol.isSign) {
        if (Sign.fromSymbol(symbol).hasPriority) {
          actualSignIndex = index;

          if (newInput[index + 1] == Sign.plus.symbol || newInput[index + 1] == Sign.minus.symbol) {
            index++;
          }
        } else {
          if (actualSignIndex == null) {
            previousSignIndex = index;
          } else {
            lastSignIndex = index;
          }
        }
      }

      if (lastSignIndex != null) {
        final priorityInput = newInput.substring(previousSignIndex + 1, lastSignIndex);
        newInput = newInput.replaceAll(priorityInput, super.compute(priorityInput).toString());

        actualSignIndex = null;
        lastSignIndex = null;
      }

      if (index == newInput.length - 1 && actualSignIndex != null) {
        final priorityInput = newInput.substring(previousSignIndex);
        newInput = newInput.replaceAll(priorityInput, super.compute(priorityInput).toString());

        actualSignIndex = null;
      }

      index++;
    }

    return super.compute(newInput);
  }
}

abstract class Calculation {
  num compute(String input) {
    String newInput = input.clearSignAmbiguity();

    int? firstSignIndex = newInput.getFirstSignIndex();
    int? nextSignIndex = newInput.getNextSignIndex(firstSignIndex);

    if (firstSignIndex == null) {
      return num.parse(newInput);
    } else {
      num result = 0;

      while (firstSignIndex != null) {
        print(newInput);
        final sign = Sign.fromSymbol(newInput[firstSignIndex]);
        final smallInput = nextSignIndex != null ? newInput.substring(0, nextSignIndex) : newInput;

        result = sign.selectOperation(smallInput).result;
        newInput = newInput.replaceRange(0, nextSignIndex, '$result');

        if (nextSignIndex != null) {
          firstSignIndex = newInput.getFirstSignIndex();
          nextSignIndex = newInput.getNextSignIndex(firstSignIndex);
        } else {
          firstSignIndex = null;
        }
      }

      return result;
    }
  }
}

extension on Sign {
  Operation selectOperation(String input) {
    switch (this) {
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

extension _StringPattern on String {
  static final parenthesis = RegExp(r'[)(]');
  static final parenthesisContent = RegExp(r'\(([^\)(]+)\)');
  static final equalMinusSignPattern = RegExp(r'(\+\-)|(\-\+)');
  static final equalPlusSignPattern = RegExp(r'(\+\+)|(\-\-)');
}

extension on String {
  String replaceParenthesis([String Function(String)? computation]) {
    return replaceAllMapped(_StringPattern.parenthesisContent, (match) {
      final newInput = match[0]!.replaceAll(_StringPattern.parenthesis, '');

      return computation?.call(newInput) ?? newInput;
    });
  }

  String clearSignAmbiguity() {
    String newInput = this;

    if (newInput.contains(_StringPattern.equalMinusSignPattern)) {
      newInput = newInput.replaceAll(_StringPattern.equalMinusSignPattern, '-');
    }

    if (newInput.contains(_StringPattern.equalPlusSignPattern)) {
      newInput = newInput.replaceAll(_StringPattern.equalPlusSignPattern, '+');
    }

    return newInput;
  }

  bool get isSign => Sign.values.map((e) => e.symbol).contains(this);

  int? getFirstSignIndex() {
    int startIndex = 0;

    if (this[startIndex] == Sign.minus.symbol) {
      startIndex++;
    }

    for (var index = startIndex; index < length; index++) {
      if (this[index].isSign) {
        return index;
      }
    }

    return null;
  }

  int? getNextSignIndex([int? firstIndex]) {
    if (firstIndex != null) {
      int startIndex = firstIndex + 1;

      if (this[startIndex] == Sign.plus.symbol || this[startIndex] == Sign.minus.symbol) {
        startIndex++;
      }

      for (var index = startIndex; index < length; index++) {
        if (this[index].isSign) {
          return index;
        }
      }
    }

    return null;
  }
}
