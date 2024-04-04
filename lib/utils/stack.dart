// Why isn't this in the std library?

import 'dart:collection';

// https://stackoverflow.com/a/70486210/9816000
extension StackCollection<T> on Queue<T> {
  void push(T element) => addLast(element);
  T? pop() => isEmpty ? null : removeLast();
}
