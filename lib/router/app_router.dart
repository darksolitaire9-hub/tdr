import 'package:go_router/go_router.dart';

import '../features/todos/presentation/pages/home_page.dart';
import '../features/todos/presentation/pages/todo_form_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      path: '/todo/new',
      builder: (_, __) => const TodoFormPage(),
    ),
    GoRoute(
      path: '/todo/edit/:id',
      builder: (_, state) => TodoFormPage(todoId: state.pathParameters['id']),
    ),
  ],
);
