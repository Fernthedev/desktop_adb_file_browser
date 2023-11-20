/// The signature of a generic comparison function.
///
/// A comparison function represents an ordering on a type of objects.
/// A total ordering on a type means that for two values, either they
/// are equal or one is greater than the other (and the latter must then be
/// smaller than the former).
///
/// A [Comparator] function represents such a total ordering by returning
///
/// * a negative integer if [a] is smaller than [b],
/// * zero if [a] is equal to [b], and
/// * a positive integer if [a] is greater than [b].
typedef AsyncComparator<T> = Future<int> Function(T a, T b);
typedef AsyncComparableGenerator<T> = Future<Comparable<T>> Function(T a, T b);

typedef ComparisonValue = int;
typedef EntryIndex = int;

// extension AsyncSort<T> on List<T> {
//   Future<void> sortAsync(AsyncComparator<T> comparator) async {
//     // Create a list of Future<MapEntry<int, int>> to store the comparison results.
//     List<Future<MapEntry<ComparisonValue, EntryIndex>>> comparisons = [];

//     // Populate the list with asynchronous comparisons in parallel.
//     for (var i = 0; i < length - 1; i++) {
//       for (var j = i + 1; j < length; j++) {
//         var comparison = comparator(this[i], this[j]);
//         var entry = comparison.then((value) => MapEntry(value, i));

//         comparisons.add(entry);
//       }
//     }

//     // Wait for all asynchronous comparisons to complete in parallel.
//     var results = await Future.wait(comparisons);

//     // Sort the indices based on the comparison results.
//     results.sort((a, b) => a.key.compareTo(b.key));

//     // Rearrange the original list based on the sorted indices.
//     for (var i = 0; i < results.length; i++) {
//       this[i] = this[results[i].value];
//     }
//   }
// }

class _AsyncSortData<T> {
  final T a;
  final T b;
  final ComparisonValue value;

  _AsyncSortData({required this.a, required this.b, required this.value});
}

extension AsyncSort<T> on List<T> {
  /// I hate this. 
  /// I wish there was an easier way to async sort
  Future<void> sortAsync(AsyncComparator<T> comparator) async {
    // Create a list of Future<MapEntry<int, int>> to store the comparison results.
    List<Future<_AsyncSortData<T>>> comparisons = [];

    // Populate the list with asynchronous comparisons in parallel.
    for (var i = 0; i < length - 1; i++) {
      for (var j = i + 1; j < length; j++) {
        var a = this[i];
        var b = this[j];

        var comparison = comparator(a, b);
        var entry = comparison
            .then((value) => _AsyncSortData<T>(a: a, b: b, value: value));

        comparisons.add(entry);
      }
    }

    // Wait for all asynchronous comparisons to complete in parallel.
    var results = await Future.wait(comparisons);

    // Place into map for retrieval of comparison value
    var resultsMap = Map<MapEntry<T, T>, _AsyncSortData<T>>.fromIterable(
        results.map((e) => MapEntry(MapEntry(e.a, e.b), e)));

    // Sort the indices based on the comparison results.
    results.sort((a, b) => resultsMap[MapEntry(a, b)]!.value);

    // Rearrange the original list based on the sorted indices.
    for (var i = 0; i < results.length; i++) {
      this[i] = this[results[i].value];
    }
  }
}
