import 'package:calculator/calculation.dart';

void main() {
  final startTime = DateTime.now();

  final result = CalculationImpl().compute('+1+(-3.99999*-4)+1-4.1/-4+(1+(1.11112312+1+(1-4)))+(-1/4)');
  final stopTime = DateTime.now();

  print('$result, in ${stopTime.difference(startTime).inMicroseconds / 1000} milliseconds');
}
