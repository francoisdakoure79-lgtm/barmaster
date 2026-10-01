import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/category.dart';
import '../../../shared/theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Category> _categories = [];
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _db.addListener(_refreshData);
  }

  @override
  void dispose() {
    _db.removeListener(_refreshData);
    _nameController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _refreshData() {
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _isLoading = true;
      try {
        _categories = _db.getAllCategories();
      } catch (e) {
        print('❌ Erreur: $e');
      }
      _isLoading = false;
    });
  }

  void _resetForm() {
    _nameController.clear();
    _iconController.clear();
    _colorController.clear();
    setState(() {
      _editingId = null;
    });
  }

  void _editCategory(Category category) {
    setState(() {
      _editingId = category.id;
      _nameController.text = category.name;
      _iconController.text = category.icon;
      _colorController.text = category.color;
    });
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    final icon = _iconController.text.trim();
    final color = _colorController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    final iconFinal = icon.isEmpty ? '📦' : icon;
    final colorFinal = color.isEmpty ? '#FFFFFF' : color;

    if (_editingId != null) {
      _db.updateCategory(_editingId!, name, iconFinal, colorFinal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Catégorie "$name" mise à jour'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      _db.addCategory(name, iconFinal, colorFinal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Catégorie "$name" ajoutée'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }

    _resetForm();
    _loadCategories();
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Supprimer la catégorie'),
        content: Text('Voulez-vous vraiment supprimer la catégorie "${category.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _db.deleteCategory(category.id);
              Navigator.pop(context);
              _loadCategories();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ Catégorie "${category.name}" supprimée'),
                  backgroundColor: AppTheme.warningOrange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingId != null ? '✏️ Modifier la catégorie' : '➕ Ajouter une catégorie',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom de la catégorie *',
                              hintText: 'Ex: Jus de fruits',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          TextField(
                            controller: _iconController,
                            decoration: const InputDecoration(
                              labelText: 'Icône (emoji)',
                              hintText: 'Ex: 🍹',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.emoji_emotions),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          TextField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Couleur (hex)',
                              hintText: 'Ex: #FF6B6B',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.color_lens),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveCategory,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: Text(
                                    _editingId != null ? 'Mettre à jour' : 'Ajouter',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (_editingId != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text('Annuler'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📋 Liste des catégories (${_categories.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (_categories.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Aucune catégorie',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ..._categories.map((category) {
                              return Card(
                                color: Colors.grey[800],
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        category.icon,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    category.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'ID: ${category.id}',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppTheme.primaryGold),
                                        onPressed: () => _editCategory(category),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppTheme.dangerRed),
                                        onPressed: () => _deleteCategory(category),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
