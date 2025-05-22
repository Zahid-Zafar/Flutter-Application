import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'note.dart';
import 'category.dart';

class DbHelper {
  static const String _notesKey = 'notes';
  static const String _categoriesKey = 'categories';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<List<Note>> getNotes(int? categoryId) async {
    final prefs = await _getPrefs();
    final notesJson = prefs.getString(_notesKey);
    if (notesJson == null) return [];
    final List<dynamic> notesList = jsonDecode(notesJson);
    final notes = notesList.map((e) => Note.fromMap(e)).toList();
    if (categoryId == null) return notes;
    return notes.where((note) => note.categoryId == categoryId).toList();
  }

  Future<void> insertNote(Note note) async {
    final prefs = await _getPrefs();
    final notes = await getNotes(null);
    final newNote = Note(
      id: notes.isEmpty ? 1 : notes.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1,
      title: note.title,
      content: note.content,
      categoryId: note.categoryId,
      createdAt: note.createdAt,
    );
    notes.add(newNote);
    await prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toMap()).toList()));
  }

  Future<void> updateNote(Note note) async {
    final prefs = await _getPrefs();
    final notes = await getNotes(null);
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      notes[index] = note;
      await prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toMap()).toList()));
    }
  }

  Future<void> deleteNote(int id) async {
    final prefs = await _getPrefs();
    final notes = await getNotes(null);
    notes.removeWhere((n) => n.id == id);
    await prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toMap()).toList()));
  }

  Future<List<Category>> getCategories() async {
    final prefs = await _getPrefs();
    final categoriesJson = prefs.getString(_categoriesKey);
    if (categoriesJson == null) return [];
    final List<dynamic> categoriesList = jsonDecode(categoriesJson);
    return categoriesList.map((e) => Category.fromMap(e)).toList();
  }

  Future<void> insertCategory(Category category) async {
    final prefs = await _getPrefs();
    final categories = await getCategories();
    final newCategory = Category(
      id: categories.isEmpty ? 1 : categories.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1,
      name: category.name,
    );
    categories.add(newCategory);
    await prefs.setString(_categoriesKey, jsonEncode(categories.map((c) => c.toMap()).toList()));
  }

  Future<void> updateCategory(Category category) async {
    final prefs = await _getPrefs();
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await prefs.setString(_categoriesKey, jsonEncode(categories.map((c) => c.toMap()).toList()));
    }
  }

  Future<void> deleteCategory(int id) async {
    final prefs = await _getPrefs();
    final categories = await getCategories();
    categories.removeWhere((c) => c.id == id);
    await prefs.setString(_categoriesKey, jsonEncode(categories.map((c) => c.toMap()).toList()));
    final notes = await getNotes(null);
    for (var note in notes) {
      if (note.categoryId == id) {
        await updateNote(Note(
          id: note.id,
          title: note.title,
          content: note.content,
          categoryId: null,
          createdAt: note.createdAt,
        ));
      }
    }
  }
}