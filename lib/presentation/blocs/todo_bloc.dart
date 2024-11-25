import 'dart:math';

import 'package:bloc_todo_test_v2/domain/entities/todo.dart';
import 'package:bloc_todo_test_v2/domain/usecases/add_todo.dart';
import 'package:bloc_todo_test_v2/domain/usecases/edit_todo.dart';
import 'package:bloc_todo_test_v2/domain/usecases/get_todos.dart';
import 'package:bloc_todo_test_v2/domain/usecases/remove_todo.dart';
import 'package:bloc_todo_test_v2/presentation/blocs/todo_event.dart';
import 'package:bloc_todo_test_v2/presentation/blocs/todo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetTodosUseCase getTodos;
  final AddTodoUseCase addTodo;
  final EditTodoUseCase editTodo;
  final RemoveTodoUseCase removeTodo;

  TodoBloc({
    required this.getTodos,
    required this.addTodo,
    required this.editTodo,
    required this.removeTodo,
  }) : super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<EditTodo>(_onEditTodo);
    on<RemoveTodo>(_onRemoveTodo);
  }
  void _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    try {
      final todos = await getTodos(event.startIndex, event.count);

      if (event.startIndex == 0) {
        // Nếu là yêu cầu từ đầu danh sách
        emit(TodoLoaded(todos: todos));
      } else {
        final currentState = state;

        if (currentState is TodoLoaded) {
          // Nối thêm vào danh sách hiện tại
          final updatedTodos = List<Todo>.from(currentState.todos)
            ..addAll(todos);
          emit(TodoLoaded(todos: updatedTodos));
        }
      }
    } catch (e) {
      emit(TodoError(message: e.toString()));
    }
  }

  void _onAddTodo(AddTodo event, Emitter<TodoState> emit) async {
    try {
      event.todo.id = DateTime.now().millisecondsSinceEpoch;
      await addTodo(event.todo);
      final currentState = state;
      if (currentState is TodoLoaded) {
        // Thêm todo vào danh sách hiện tại
        final updatedTodos = List<Todo>.from(currentState.todos)
          ..add(event.todo);
        emit(TodoLoaded(todos: updatedTodos));
      } else {
        // Nếu trạng thái không phải TodoLoaded, tải lại danh sách
        final todos = await getTodos(0, 10);
        emit(TodoLoaded(todos: todos));
      }
    } catch (e) {
      emit(TodoError(message: e.toString()));
    }
  }

  void _onRemoveTodo(RemoveTodo event, Emitter<TodoState> emit) async {
    try {
      await removeTodo(event.id);
      final currentState = state;

      if (currentState is TodoLoaded) {
        // Xóa todo khỏi danh sách hiện tại
        final updatedTodos =
            currentState.todos.where((todo) => todo.id != event.id).toList();
        emit(TodoLoaded(todos: updatedTodos));
      }
    } catch (e) {
      emit(TodoError(message: e.toString()));
    }
  }

  void _onEditTodo(EditTodo event, Emitter<TodoState> emit) async {
    try {
      await editTodo(event.todo);
      final currentState = state;

      if (currentState is TodoLoaded) {
        // Cập nhật danh sách hiện tại với todo đã chỉnh sửa
        final updatedTodos = currentState.todos.map((todo) {
          return todo.id == event.todo.id ? event.todo : todo;
        }).toList();
        emit(TodoLoaded(todos: updatedTodos));
      }
    } catch (e) {
      emit(TodoError(message: e.toString()));
    }
  }
}
