typedef ListenerCallback<T> = void Function(T item);

class ListenableHolder<T> {
  EventListenable<T>? _listenable;

  ListenableHolder(this._listenable);

  void dispose() {
    _listenable?.removeListener(this);
    _listenable = null;
  }
}

class EventListenable<T> {
  final Map<ListenableHolder<T>, ListenerCallback<T>> _listeners = {};

  ListenableHolder<T> addListener(ListenerCallback<T> callback) {
    var holder = ListenableHolder<T>(this);
    _listeners[holder] = callback;

    return holder;
  }

  void removeListener(ListenableHolder<T> holder) {
    _listeners.remove(holder);
  }

  void invoke(T v) {
    _listeners.forEach((key, value) => value(v));
  }
}
