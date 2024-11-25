import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class GetTodosUseCase {
  final TodoRepository repository;

  GetTodosUseCase(this.repository);

  Future<List<Todo>> call(int startIndex, int limit) async {
    final todos = await repository.getTodos(startIndex, limit);
    print("Fetched Todos: ${todos.length}");
    return todos;
  }
}
