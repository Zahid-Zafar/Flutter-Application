import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'note.dart';
import 'category.dart';
import 'DBHelper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NoteTakingApp());
}

class NoteTakingApp extends StatelessWidget {
  const NoteTakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Note App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.teal[50],
          labelStyle: TextStyle(color: Colors.teal[800]),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
            elevation: 4,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          elevation: 4,
          shadowColor: Colors.tealAccent,
          backgroundColor: Colors.teal,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  _NotesHomePageState createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  final DbHelper _dbHelper = DbHelper();
  List<Note> _notes = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _showFavoritesOnly = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await _refreshNotes();
      await _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshNotes() async {
    final notes = await _dbHelper.getNotes(_selectedCategoryId);
    setState(() {
      _notes = _showFavoritesOnly ? notes.where((note) => note.isFavorite).toList() : notes;
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _dbHelper.getCategories();
    setState(() => _categories = categories);
  }

  Future<void> _toggleFavorite(Note note) async {
    setState(() => _isLoading = true);
    try {
      final updatedNote = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        categoryId: note.categoryId,
        createdAt: note.createdAt,
        isFavorite: !note.isFavorite,
      );
      await _dbHelper.updateNote(updatedNote);
      await _refreshNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedNote.isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorite: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNoteDialog({Note? note}) {
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedCategoryId = note.categoryId;
    } else {
      _titleController.clear();
      _contentController.clear();
      _selectedCategoryId = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          note == null ? 'New Note' : 'Edit Note',
          style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter note title',
                  prefixIcon: Icon(Icons.title, color: Colors.teal[600]),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter note content',
                  prefixIcon: Icon(Icons.description, color: Colors.teal[600]),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category, color: Colors.teal[600]),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('No Category'),
                  ),
                  ..._categories.map((category) => DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.teal[800])),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title and content cannot be empty'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() => _isLoading = true);
                    try {
                      final noteToSave = Note(
                        id: note?.id ?? 0,
                        title: _titleController.text.trim(),
                        content: _contentController.text.trim(),
                        categoryId: _selectedCategoryId,
                        createdAt: note?.createdAt ?? DateTime.now(),
                        isFavorite: note?.isFavorite ?? false,
                      );
                      if (note == null) {
                        await _dbHelper.insertNote(noteToSave);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note added successfully')),
                        );
                      } else {
                        await _dbHelper.updateNote(noteToSave);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note updated successfully')),
                        );
                      }
                      Navigator.pop(context);
                      await _refreshNotes();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving note: $e'), backgroundColor: Colors.red),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
            child: Text(note == null ? 'Save' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Manage Categories', style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'New Category',
                  hintText: 'Enter category name',
                  prefixIcon: Icon(Icons.add, color: Colors.teal[600]),
                ),
              ),
              const SizedBox(height: 16),
              if (_categories.isEmpty)
                const Text('No categories yet.', style: TextStyle(color: Colors.grey))
              else
                ..._categories.map((category) => ListTile(
                      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () {
                              _categoryController.text = category.name;
                              _showEditCategoryDialog(category);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text(
                                      'Are you sure you want to delete "${category.name}"? Notes in this category will be unassigned.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setState(() => _isLoading = true);
                                try {
                                  await _dbHelper.deleteCategory(category.id);
                                  await _refreshData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Category "${category.name}" deleted')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error deleting category: $e'), backgroundColor: Colors.red),
                                  );
                                } finally {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.teal[800])),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_categoryController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category name cannot be empty'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() => _isLoading = true);
                    try {
                      await _dbHelper.insertCategory(Category(id: 0, name: _categoryController.text.trim()));
                      _categoryController.clear();
                      await _loadCategories();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category added successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding category: $e'), backgroundColor: Colors.red),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    _categoryController.text = category.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Category', style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _categoryController,
          decoration: InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter new category name',
            prefixIcon: Icon(Icons.edit, color: Colors.teal[600]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.teal[800])),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_categoryController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category name cannot be empty'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() => _isLoading = true);
                    try {
                      await _dbHelper.updateCategory(Category(id: category.id, name: _categoryController.text.trim()));
                      _categoryController.clear();
                      Navigator.pop(context);
                      await _refreshData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category updated successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating category: $e'), backgroundColor: Colors.red),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white),
            onPressed: _isLoading ? null : _showCategoryDialog,
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.teal,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    color: Colors.teal[50],
                    child: DropdownButtonFormField<int?>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: _showFavoritesOnly ? 'Favorites Only' : 'Filter by Category',
                        prefixIcon: Icon(
                          _showFavoritesOnly ? Icons.star : Icons.filter_list,
                          color: Colors.teal[600],
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Notes'),
                        ),
                        ..._categories.map((category) => DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(category.name),
                            )),
                      ],
                      onChanged: _showFavoritesOnly
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCategoryId = value;
                                _refreshNotes();
                              });
                            },
                    ),
                  ),
                  Expanded(
                    child: _notes.isEmpty
                        ? Center(
                            child: Text(
                              _showFavoritesOnly ? 'No favorite notes yet!' : 'No notes yet. Add one!',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _notes.length,
                            itemBuilder: (context, index) {
                              final note = _notes[index];
                              final category = _categories.firstWhere(
                                (cat) => cat.id == note.categoryId,
                                orElse: () => Category(id: 0, name: 'No Category'),
                              );
                              return Card(
                                elevation: note.isFavorite ? 12 : 8,
                                color: note.isFavorite ? Colors.yellow[50] : Colors.white,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    note.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[800],
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
                                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Category: ${category.name}',
                                        style: TextStyle(color: Colors.teal[600], fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Created: ${DateFormat('MMM dd, yyyy').format(note.createdAt)}',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: Icon(
                                              note.isFavorite ? Icons.star : Icons.star_border,
                                              color: note.isFavorite ? Colors.yellow[700] : Colors.grey,
                                              size: 20,
                                            ),
                                            onPressed: _isLoading ? null : () => _toggleFavorite(note),
                                            tooltip: note.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showNoteDialog(note: note),
                                  onLongPress: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Note'),
                                        content: Text('Are you sure you want to delete "${note.title}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      setState(() => _isLoading = true);
                                      try {
                                        await _dbHelper.deleteNote(note.id);
                                        await _refreshNotes();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Note "${note.title}" deleted')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error deleting note: $e'), backgroundColor: Colors.red),
                                        );
                                      } finally {
                                        setState(() => _isLoading = false);
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : () => _showNoteDialog(),
              backgroundColor: Colors.teal,
              tooltip: 'Add Note',
              child: const Icon(Icons.add, size: 28),
            ),
          ),
          Positioned(
            left: 30,
            bottom: 10,
            child: FloatingActionButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                        _selectedCategoryId = null;
                        _refreshNotes();
                      });
                    },
              backgroundColor: _showFavoritesOnly ? Colors.yellow[700] : Colors.teal[700],
              tooltip: _showFavoritesOnly ? 'Show All Notes' : 'Show Favorite Notes',
              child: Icon(
                _showFavoritesOnly ? Icons.star : Icons.star_border,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}