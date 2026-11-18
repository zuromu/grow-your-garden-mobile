import 'package:flutter_test/flutter_test.dart';
import 'package:grow_your_garden_mobile/main.dart';

void main() {
  testWidgets('Garden Page opens successfully', (WidgetTester tester) async {
    // Launch the application
    await tester.pumpWidget(const GrowYourGardenApp());

    // Verify that the Garden Page is displayed
    expect(find.text('Garden'), findsOneWidget);
    expect(find.text('Community garden'), findsOneWidget);
    expect(find.text('Plant of the week'), findsOneWidget);
  });
}
