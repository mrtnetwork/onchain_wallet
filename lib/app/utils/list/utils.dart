class ListUtils {
  static List<List<T>> splitList<T>(List<T> inputList, {int chunkSize = 50}) {
    List<List<T>> result = [];
    for (int i = 0; i < inputList.length; i += chunkSize) {
      result.add(inputList.sublist(
          i, i + chunkSize > inputList.length ? inputList.length : i + chunkSize));
    }
    return result;
  }
}
