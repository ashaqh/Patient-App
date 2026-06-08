import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carevault/presentation/screens/app.dart';
import 'package:carevault/presentation/widgets/common/glass_widgets.dart';

void main() {
  testWidgets('App renders with all navigation tabs', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Initial rendering shows splash screen
    expect(find.text('Apprise Apps'), findsOneWidget);

    // Wait for splash screen to complete (2.5s duration)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify app title appears
    expect(find.text('CareVault'), findsAtLeastNWidgets(1));
    
    // Verify bottom navigation tabs appear in custom glass navigation bar
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Meds'), findsOneWidget);
    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('Follow-ups'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Vitals'), findsOneWidget);
    
    // Verify welcome message appears on dashboard
    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('App navigation between tabs works', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Wait for splash screen to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Start on Home tab
    expect(find.text('Welcome back!'), findsOneWidget);
    
    // Tap on Meds tab
    await tester.tap(find.text('Meds'));
    await tester.pumpAndSettle();
    
    // Should see medicine list screen
    expect(find.text('My Medicines'), findsOneWidget);
    
    // Tap on Vault tab
    await tester.tap(find.text('Vault'));
    await tester.pumpAndSettle();
    
    // Should see prescriptions screen (Prescription Vault)
    expect(find.text('Prescription Vault'), findsOneWidget);
    
    // Tap on Follow-ups tab
    await tester.tap(find.text('Follow-ups'));
    await tester.pumpAndSettle();
    
    // Should see follow-ups screen
    expect(find.text('Follow-ups'), findsAtLeastNWidgets(1));
    
    // Tap on Timeline tab
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    
    // Should see timeline screen
    expect(find.text('Health Timeline'), findsOneWidget);
    
    // Return to Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    
    // Should be back on dashboard
    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('Gradient FAB appears on screens', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Wait for splash screen to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Check custom GradientFab on Home/Dashboard
    expect(find.byType(GradientFab), findsOneWidget);
    
    // Navigate to Meds
    await tester.tap(find.text('Meds'));
    await tester.pumpAndSettle();
    
    // GradientFab should still be visible on Meds screen
    expect(find.byType(GradientFab), findsOneWidget);
    
    // Navigate to Vault
    await tester.tap(find.text('Vault'));
    await tester.pumpAndSettle();
    
    // GradientFab should be visible on Vault (Prescriptions) screen
    expect(find.byType(GradientFab), findsOneWidget);
    
    // Navigate to Follow-ups
    await tester.tap(find.text('Follow-ups'));
    await tester.pumpAndSettle();
    
    // GradientFab should be visible on Follow-ups screen
    expect(find.byType(GradientFab), findsOneWidget);
  });

  testWidgets('App theme has correct configuration', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Wait for splash screen to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify MaterialApp inherits the correct title
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
    expect(materialApp.title, equals('CareVault'));
    expect(materialApp.theme?.primaryColor, isNotNull);
  });

  testWidgets('App handles loading states gracefully', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Initial rendering shows splash screen
    expect(find.text('Apprise Apps'), findsOneWidget);
    
    // Wait for the splash screen to complete (2.5s duration)
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // App should have rendered successfully
    expect(find.text('CareVault'), findsAtLeastNWidgets(1));
  });
}
