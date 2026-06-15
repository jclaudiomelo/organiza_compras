import 'package:flutter/material.dart';
import '../controllers/purchase_controller.dart';

class CategoriesScreen extends StatefulWidget {
  final PurchaseController controller;

  const CategoriesScreen({super.key, required this.controller});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<int> _availableColors = [
    0xFF2ECC71, // Green
    0xFF3498DB, // Blue
    0xFFE67E22, // Orange
    0xFFE91E63, // Pink
    0xFFE74C3C, // Red
    0xFF9B59B6, // Purple
    0xFF1ABC9C, // Teal
    0xFFF1C40F, // Yellow
  ];

  final List<IconData> _availableIcons = [
    Icons.restaurant,
    Icons.local_drink,
    Icons.cleaning_services,
    Icons.bubble_chart,
    Icons.shopping_bag,
    Icons.home,
    Icons.directions_car,
    Icons.local_pharmacy,
    Icons.laptop,
    Icons.pets,
    Icons.card_giftcard,
    Icons.build,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final categories = widget.controller.categories;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0E17),
          appBar: AppBar(
            title: const Text('Categorias', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF0F0E17),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: categories.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final name = cat['name'] as String;
                    final colorValue = cat['color'] as int;
                    final iconCode = cat['icon_code'] as int;
                    
                    final color = Color(colorValue);
                    final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
                    
                    // Don't allow deleting the default 'Outros' category to prevent logic breakdown
                    final isProtected = name == 'Outros';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16161A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon Badge
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color),
                            ),
                            const SizedBox(width: 16),
                            // Name
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Actions
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                              onPressed: () => _showCategoryDialog(
                                context,
                                id: cat['id'] as int,
                                currentName: name,
                                currentColor: colorValue,
                                currentIconCode: iconCode,
                              ),
                            ),
                            if (!isProtected)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _showDeleteConfirmation(context, cat['id'] as int, name),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCategoryDialog(context),
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nova Categoria'),
          ),
        );
      },
    );
  }

  void _showCategoryDialog(
    BuildContext context, {
    int? id,
    String? currentName,
    int? currentColor,
    int? currentIconCode,
  }) {
    final isEditing = id != null;
    final nameController = TextEditingController(text: currentName ?? '');
    
    int selectedColor = currentColor ?? _availableColors.first;
    int selectedIconCode = currentIconCode ?? _availableIcons.first.codePoint;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16161A),
              title: Text(
                isEditing ? 'Editar Categoria' : 'Nova Categoria',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name TextField
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nome da Categoria',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F0E17),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Color selection title
                    const Text('Selecione uma Cor:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
                    // Color Grid
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableColors.length,
                        itemBuilder: (context, index) {
                          final colValue = _availableColors[index];
                          final isColSelected = selectedColor == colValue;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedColor = colValue;
                                });
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(colValue),
                                  shape: BoxShape.circle,
                                  border: isColSelected
                                      ? Border.all(color: Colors.white, width: 3)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Icon selection title
                    const Text('Selecione um Ícone:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
                    // Icon Grid
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableIcons.length,
                        itemBuilder: (context, index) {
                          final iconData = _availableIcons[index];
                          final isIconSelected = selectedIconCode == iconData.codePoint;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedIconCode = iconData.codePoint;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isIconSelected
                                      ? Colors.deepPurpleAccent.withOpacity(0.3)
                                      : const Color(0xFF0F0E17),
                                  borderRadius: BorderRadius.circular(10),
                                  border: isIconSelected
                                      ? Border.all(color: Colors.deepPurpleAccent, width: 2)
                                      : null,
                                ),
                                child: Icon(
                                  iconData,
                                  color: isIconSelected ? Colors.white : Colors.grey,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    Navigator.pop(dialogContext);

                    bool success;
                    if (isEditing) {
                      success = await widget.controller.editCategory(
                        id,
                        currentName!,
                        name,
                        selectedColor,
                        selectedIconCode,
                      );
                    } else {
                      success = await widget.controller.addCategory(
                        name,
                        selectedColor,
                        selectedIconCode,
                      );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success 
                            ? 'Categoria salva com sucesso!' 
                            : (widget.controller.errorMessage ?? 'Erro ao salvar categoria.')
                          ),
                          backgroundColor: success ? Colors.green : Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, int id, String categoryName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          title: const Text('Excluir Categoria', style: TextStyle(color: Colors.white)),
          content: Text(
            'Deseja realmente excluir a categoria "$categoryName"?\n\nTodos os itens desta categoria serão reclassificados para "Outros".',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await widget.controller.deleteCategory(id, categoryName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Categoria excluída com sucesso!' 
                        : (widget.controller.errorMessage ?? 'Erro ao excluir categoria.')
                      ),
                      backgroundColor: success ? Colors.redAccent : Colors.grey,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}
