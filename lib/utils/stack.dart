// Why isn't this in the std library?

import 'dart:collection';

// https://stackoverflow.com/a/70486210/9816000
class StackCollection<T> {
  final Queue<T> _queue;

  StackCollection() : _queue = Queue<T>();
  StackCollection.fromQueue(this._queue);

  void push(T element) {
    _queue.addLast(element);
  }

  T? pop() {
    return isEmpty ? null : _queue.removeLast();
  }

  void clear() {
    _queue.clear();
  }

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  int get length => _queue.length;
}
