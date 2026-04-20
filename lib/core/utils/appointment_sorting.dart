List<T> sortByScheduledAt<T>(
  Iterable<T> items,
  DateTime Function(T item) getScheduledAt,
) {
  final sortedItems = items.toList();
  sortedItems.sort(
    (left, right) => getScheduledAt(left).compareTo(getScheduledAt(right)),
  );
  return sortedItems;
}