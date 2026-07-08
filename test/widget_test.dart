import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EventFlowApp());
    expect(find.text('EventFlow'), findsOneWidget);
  });
}
