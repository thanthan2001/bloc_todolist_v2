import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class AddTodoUseCase {
  final TodoRepository repository;

  AddTodoUseCase(this.repository);

  Future<void> call(Todo todo) async {
    return repository.addTodo(todo);
  }
}
