import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../domain/entities/todo.dart';
import '../blocs/todo_bloc.dart';
import '../blocs/todo_event.dart';
import '../blocs/todo_state.dart';
import '../../injection.dart'; // Import file injection

@RoutePage()
class TodoPage extends StatelessWidget {
  static const int _pageSize = 10;

  // Tạo PagingController cố định
  final PagingController<int, Todo> _pagingController =
      PagingController(firstPageKey: 0);

  TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final todoBloc = getIt<TodoBloc>();

    // Lắng nghe yêu cầu tải trang
    _pagingController.addPageRequestListener((pageKey) {
      todoBloc.add(LoadTodos(pageKey, _pageSize));
    });

    return BlocProvider(
      create: (_) => todoBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todo List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddTodoDialog(context, todoBloc),
            ),
          ],
        ),
        body: BlocListener<TodoBloc, TodoState>(
          listener: (context, state) {
            if (state is TodoLoaded) {
              final isLastPage = state.todos.length < _pageSize;

              if (_pagingController.itemList?.isEmpty ?? true) {
                if (isLastPage) {
                  _pagingController.appendLastPage(state.todos);
                } else {
                  _pagingController.appendPage(state.todos, _pageSize);
                }
              } else {
                final alreadyLoaded = _pagingController.itemList ?? [];
                final newItems =
                    state.todos.skip(alreadyLoaded.length).toList();

                if (newItems.isNotEmpty) {
                  if (isLastPage) {
                    _pagingController.appendLastPage(newItems);
                  } else {
                    final nextPageKey = _pagingController.itemList!.length;
                    _pagingController.appendPage(newItems, nextPageKey);
                  }
                }
              }
            } else if (state is TodoError) {
              _pagingController.error = state.message;
            }
          },
          child: PagedListView<int, Todo>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<Todo>(
              itemBuilder: (context, todo, index) =>
                  _buildTodoItem(context, todo, todoBloc),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoItem(BuildContext context, Todo todo, TodoBloc todoBloc) {
    return ListTile(
      title: Text(todo.title ?? 'No Title'),
      subtitle: Text(todo.description ?? 'No Description'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditTodoDialog(context, todo, todoBloc),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => todoBloc.add(RemoveTodo(todo.id!)),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, TodoBloc todoBloc) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final todo = Todo(
                title: titleController.text,
                description: descriptionController.text,
                isCompleted: false,
              );
              todoBloc.add(AddTodo(todo: todo));
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, Todo todo, TodoBloc todoBloc) {
    final titleController = TextEditingController(text: todo.title);
    final descriptionController = TextEditingController(text: todo.description);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedTodo = Todo(
                id: todo.id,
                title: titleController.text,
                description: descriptionController.text,
                isCompleted: todo.isCompleted,
              );
              todoBloc.add(EditTodo(todo: updatedTodo));
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
