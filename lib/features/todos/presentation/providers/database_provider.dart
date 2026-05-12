import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/local/app_database.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../domain/repositories/i_todo_repository.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
ITodoRepository todoRepository(Ref ref) =>
    TodoRepositoryImpl(ref.watch(appDatabaseProvider));

