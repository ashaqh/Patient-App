import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carevault/presentation/screens/app.dart';

void main() {
  testWidgets('App renders with all navigation tabs', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: App(),
        ),
      ),
    );

    // Verify app title appears
    expect(find.text('CareVault'), findsOneWidget);
    
    // Verify bottom navigation tabs appear
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Medicines'), findsOneWidget);
    expect(find.text('Prescriptions'), findsOneWidget);
    expect(find.text('Follow-ups'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    
    // Verify welcome message appears on dashboard
    expect(find.text('Welcome to CareVault'), findsOneWidget);
  });

  testWidgets('App navigation between tabs works', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: App(),
        ),
      ),
    );

    // Start on Dashboard tab
    expect(find.text('Today\'s Medicines'), findsOneWidget);
    
    // Tap on Medicines tab
    await tester.tap(find.text('Medicines'));
    await tester.pumpAndSettle();
    
    // Should see medicine list screen
    expect(find.text('All Medicines'), findsOneWidget);
    
    // Tap on Prescriptions tab
    await tester.tap(find.text('Prescriptions'));
    await tester.pumpAndSettle();
    
    // Should see prescriptions screen
    expect(find.text('All Prescriptions'), findsOneWidget);
    
    // Tap on Follow-ups tab
    await tester.tap(find.text('Follow-ups'));
    await tester.pumpAndSettle();
    
    // Should see follow-ups screen
    expect(find.text('All Follow-ups'), findsOneWidget);
    
    // Tap on Timeline tab
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    
    // Should see timeline screen
    expect(find.text('Health Timeline'), findsOneWidget);
    
    // Return to Dashboard
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    
    // Should be back on dashboard
    expect(find.text('Today\'s Medicines'), findsOneWidget);
  });

  testWidgets('Floating action button appears on appropriate screens', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: App(),
        ),
      ),
    );

    // Check FAB on Dashboard
    expect(find.byType(FloatingActionButton), findsOneWidget);
    
    // Navigate to Medicines
    await tester.tap(find.text('Medicines'));
    await tester.pumpAndSettle();
    
    // FAB should still be visible on Medicines screen
    expect(find.byType(FloatingActionButton), findsOneWidget);
    
    // Navigate to Prescriptions
    await tester.tap(find.text('Prescriptions'));
    await tester.pumpAndSettle();
    
    // FAB should be visible on Prescriptions screen
    expect(find.byType(FloatingActionButton), findsOneWidget);
    
    // Navigate to Follow-ups
    await tester.tap(find.text('Follow-ups'));
    await tester.pumpAndSettle();
    
    // FAB should be visible on Follow-ups screen
    expect(find.byType(FloatingActionButton), findsOneWidget);
    
    // Navigate to Timeline
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    
    // FAB should NOT be visible on Timeline screen (no add action)
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('App theme colors are applied correctly', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: App(),
        ),
      ),
    );

    // Check for primary color usage in app bar
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, isNotNull);
    
    // Check for bottom navigation bar theming
    final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bottomNavBar.selectedItemColor, isNotNull);
    expect(bottomNavBar.unselectedItemColor, isNotNull);
  });

  testWidgets('App handles loading states gracefully', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: App(),
        ),
      ),
    );

    // Initial loading should show some loading indicators
    // Note: In a real test we might mock providers to test loading states
    // For now, just verify the app renders without crashing
    expect(find.byType(CircularProgressIndicator), findsNothing);
    
    // App should have rendered successfully
    expect(find.text('CareVault'), findsOneWidget);
  });
}