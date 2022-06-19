import 'package:calculator/calculus.dart';

void main() {
  final startTime = DateTime.now();
  final result = Calculus('+1+3*4++1+-4.1/-4+(1+(1+1+(1-4)))').result;
  final stopTime = DateTime.now();

  print('$result, in ${stopTime.difference(startTime).inMicroseconds / 1000} milliseconds');
}
