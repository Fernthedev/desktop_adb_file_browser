
///
/// Sorts directories (ends with /) first then files, finally alphabetical
///
int fileSort(String a, String b) {
  final aIsDir = a.endsWith("/");
  final bIsDir = b.endsWith("/");
  if (aIsDir == bIsDir) return 0;

  if (a.endsWith("/")) {
    return -1;
  }
  if (b.endsWith("/")) {
    return 1;
  }

  return 0;
}
