// Smoke test: ensures the app widget tree builds without throwing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo_app/app.dart';
import 'package:todo_app/core/providers/theme_provider.dart';
import 'package:todo_app/core/data/local/app_database.dart';
import 'package:todo_app/features/todos/presentation/providers/database_provider.dart';

class MockDb extends Mock implements AppDatabase {}

void main() {
  testWidgets('App builds without error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockDb = MockDb();

    // Stub watchTodos to return an empty list stream
    when(() => mockDb.watchTodos(
          completed: any(named: 'completed'),
          search: any(named: 'search'),
        )).thenAnswer((_) => Stream.value([]));

    // Stub close to do nothing
    when(() => mockDb.close()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(mockDb),
        ],
        child: const App(),
      ),
    );

    // App title is rendered
    expect(find.text('My Todos'), findsOneWidget);
  });
}
