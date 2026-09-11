import 'package:flutter_test/flutter_test.dart';
import 'package:habitloop/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitLoopApp());
    await tester.pumpAndSettle();

    expect(find.text('Habits Tracker'), findsWidgets);
  });
}
