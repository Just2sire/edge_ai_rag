import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/indexed_doc.dart';

class IndexedDocumentsNotifier extends StateNotifier<List<IndexedDocument>> {
  IndexedDocumentsNotifier() : super([]);

  void setInitialDocs(List<IndexedDocument> docs) {
    state = docs;
  }

  void addDocument(IndexedDocument doc) {
    state = [...state.where((d) => d.id != doc.id), doc];
  }

  void removeDocument(String id) {
    state = state.where((d) => d.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

final indexedDocumentsProvider =
    StateNotifierProvider<IndexedDocumentsNotifier, List<IndexedDocument>>(
        (ref) {
  return IndexedDocumentsNotifier();
});
