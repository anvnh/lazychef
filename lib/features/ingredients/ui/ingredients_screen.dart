import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_bottom_bar.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/features/history/models/history_scan.dart';
import 'package:lazychef/features/history/providers/history_provider.dart';
import 'package:lazychef/features/scan/data/scan_repository.dart';
import 'package:lazychef/features/scan/utils/scan_image_picker.dart';

enum _IngredientFilter {
  all('All'),
  latest('Latest scan'),
  fruits('Fruits'),
  vegetables('Vegetables'),
  protein('Protein'),
  dairy('Dairy'),
  grains('Grains'),
  pantry('Pantry'),
  highConfidence('High confidence');

  const _IngredientFilter(this.label);

  final String label;
}

enum _IngredientCardAction { edit, remove }

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  final _searchController = TextEditingController();
  _IngredientFilter _selectedFilter = _IngredientFilter.latest;
  _IngredientInventoryItem? _editingIngredient;
  bool _isAddingIngredient = false;
  bool _isSavingIngredient = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _startAddingIngredient() {
    setState(() {
      _isAddingIngredient = true;
      _editingIngredient = null;
    });
  }

  void _startEditingIngredient(_IngredientInventoryItem ingredient) {
    setState(() {
      _editingIngredient = ingredient;
      _isAddingIngredient = false;
    });
  }

  void _cancelIngredientEditor() {
    setState(() {
      _isAddingIngredient = false;
      _editingIngredient = null;
    });
  }

  Future<void> _saveIngredient({
    required _InventoryIngredientDraft draft,
    required List<HistoryScan> scans,
  }) async {
    final ingredientName = draft.name.trim();
    if (ingredientName.isEmpty || _isSavingIngredient) {
      return;
    }

    setState(() {
      _isSavingIngredient = true;
    });

    try {
      final editingIngredient = _editingIngredient;
      if (_isAddingIngredient) {
        await _addIngredientToLatestScan(draft, scans);
      } else if (editingIngredient != null) {
        await _updateIngredientInScans(
          ingredient: editingIngredient,
          draft: draft,
          scans: scans,
        );
      }

      if (!mounted) {
        return;
      }

      _cancelIngredientEditor();
      ref.invalidate(scanHistoryProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredient changes saved.')),
      );
    } on ScanUploadException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingIngredient = false;
        });
      }
    }
  }

  Future<void> _removeIngredient({
    required _IngredientInventoryItem ingredient,
    required List<HistoryScan> scans,
  }) async {
    if (_isSavingIngredient) {
      return;
    }

    setState(() {
      _isSavingIngredient = true;
    });

    try {
      final repository = ref.read(scanRepositoryProvider);
      final targetName = ingredient.name.toLowerCase().trim();
      final affectedScans = scans.where(
        (scan) => scan.detectedIngredients.any(
          (scanIngredient) =>
              scanIngredient.name.toLowerCase().trim() == targetName,
        ),
      );

      for (final scan in affectedScans) {
        await repository.updateScanIngredients(
          scanId: scan.id,
          ingredients: scan.detectedIngredients
              .where(
                (scanIngredient) =>
                    scanIngredient.name.toLowerCase().trim() != targetName,
              )
              .map(_scanIngredientUpdate)
              .toList(),
        );
      }

      if (!mounted) {
        return;
      }

      if (_editingIngredient?.name == ingredient.name) {
        _cancelIngredientEditor();
      }
      ref.invalidate(scanHistoryProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingredient removed.')));
    } on ScanUploadException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingIngredient = false;
        });
      }
    }
  }

  Future<void> _addIngredientToLatestScan(
    _InventoryIngredientDraft draft,
    List<HistoryScan> scans,
  ) async {
    if (scans.isEmpty) {
      throw const ScanUploadException(
        'Scan an image before adding ingredients.',
      );
    }

    final latestScan = scans.first;
    final ingredients = [
      ...latestScan.detectedIngredients.map(_scanIngredientUpdate),
      ScanIngredientUpdate(
        name: draft.name,
        confidence: null,
        quantity: draft.quantity,
        expiryDate: draft.expiryDate,
      ),
    ];

    await ref
        .read(scanRepositoryProvider)
        .updateScanIngredients(scanId: latestScan.id, ingredients: ingredients);
  }

  Future<void> _updateIngredientInScans({
    required _IngredientInventoryItem ingredient,
    required _InventoryIngredientDraft draft,
    required List<HistoryScan> scans,
  }) async {
    final repository = ref.read(scanRepositoryProvider);
    final targetName = ingredient.name.toLowerCase().trim();
    final affectedScans = scans.where(
      (scan) => scan.detectedIngredients.any(
        (scanIngredient) =>
            scanIngredient.name.toLowerCase().trim() == targetName,
      ),
    );

    for (final scan in affectedScans) {
      await repository.updateScanIngredients(
        scanId: scan.id,
        ingredients: scan.detectedIngredients.map((scanIngredient) {
          if (scanIngredient.name.toLowerCase().trim() == targetName) {
            return ScanIngredientUpdate(
              name: draft.name,
              confidence: scanIngredient.confidence,
              quantity: draft.quantity,
              expiryDate: draft.expiryDate,
            );
          }

          return _scanIngredientUpdate(scanIngredient);
        }).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanHistory = ref.watch(scanHistoryProvider);

    return LazyChefScaffold(
      bottomNavigationBar: const AppBottomBar(currentIndex: 2),
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(scanHistoryProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'My ingredients',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: Color(0xFF2C3236),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Scan shelf',
                    onPressed: () => showScanImagePickerOptions(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: () {
                      ref.invalidate(scanHistoryProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.only(left: 15, right: 10),
                child: Text(
                  'INGREDIENTS FROM SAVED SCANS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFC85D3B),
                    letterSpacing: 0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SearchField(controller: _searchController),
              const SizedBox(height: 16),
              _FilterChips(
                selectedFilter: _selectedFilter,
                onSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
              const SizedBox(height: 20),
              scanHistory.when(
                loading: () => const _IngredientsLoading(),
                error: (error, _) => _IngredientsError(
                  error: error,
                  onRetry: () {
                    ref.invalidate(scanHistoryProvider);
                  },
                ),
                data: (scans) {
                  final ingredients = _filterIngredients(
                    scans: scans,
                    query: _searchController.text,
                    filter: _selectedFilter,
                  );
                  final activeEditor =
                      _isAddingIngredient || _editingIngredient != null;

                  if (scans.isEmpty) {
                    return const _EmptyIngredients();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppButton.secondary(
                        label: 'Add ingredient to latest scan',
                        icon: Icons.add_rounded,
                        onPressed: _startAddingIngredient,
                      ),
                      const SizedBox(height: 14),
                      if (activeEditor) ...[
                        _InventoryIngredientEditorCard(
                          key: ValueKey(
                            _editingIngredient?.name ?? 'add-ingredient',
                          ),
                          initialIngredient: _editingIngredient,
                          actionLabel: _isAddingIngredient ? 'Add' : 'Save',
                          isSaving: _isSavingIngredient,
                          onSave: (draft) {
                            _saveIngredient(draft: draft, scans: scans);
                          },
                          onCancel: _cancelIngredientEditor,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (ingredients.isEmpty)
                        const _NoMatchingIngredients()
                      else
                        _IngredientsGrid(
                          ingredients: ingredients,
                          isSaving: _isSavingIngredient,
                          onEdit: _startEditingIngredient,
                          onRemove: (ingredient) {
                            _removeIngredient(
                              ingredient: ingredient,
                              scans: scans,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search saved ingredients',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selectedFilter, required this.onSelected});

  final _IngredientFilter selectedFilter;
  final ValueChanged<_IngredientFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _IngredientFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: selectedFilter == filter,
              onSelected: (_) => onSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _IngredientsGrid extends StatelessWidget {
  const _IngredientsGrid({
    required this.ingredients,
    required this.isSaving,
    required this.onEdit,
    required this.onRemove,
  });

  final List<_IngredientInventoryItem> ingredients;
  final bool isSaving;
  final ValueChanged<_IngredientInventoryItem> onEdit;
  final ValueChanged<_IngredientInventoryItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ingredients.length} saved ingredients',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: const Color(0xFF6A5D51)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: 224,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                return _IngredientCard(
                  ingredient: ingredients[index],
                  isSaving: isSaving,
                  onEdit: () => onEdit(ingredients[index]),
                  onRemove: () => onRemove(ingredients[index]),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({
    required this.ingredient,
    required this.isSaving,
    required this.onEdit,
    required this.onRemove,
  });

  final _IngredientInventoryItem ingredient;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconSpec = _ingredientIconSpec(ingredient.name);
    final quantity = ingredient.quantity?.trim();
    final expiryDate = ingredient.expiryDate?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconSpec.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconSpec.icon, color: iconSpec.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient.confidenceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFC85D3B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: PopupMenuButton<_IngredientCardAction>(
                    enabled: !isSaving,
                    tooltip: 'Ingredient actions',
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) {
                      switch (action) {
                        case _IngredientCardAction.edit:
                          onEdit();
                        case _IngredientCardAction.remove:
                          onRemove();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _IngredientCardAction.edit,
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _IngredientCardAction.remove,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFC85D3B),
                            ),
                            SizedBox(width: 10),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              ingredient.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if ((quantity != null && quantity.isNotEmpty) ||
                (expiryDate != null && expiryDate.isNotEmpty)) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (quantity != null && quantity.isNotEmpty)
                    _inventoryPill(quantity),
                  if (expiryDate != null && expiryDate.isNotEmpty)
                    _inventoryPill('Exp $expiryDate'),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Seen in ${ingredient.scanCount} ${ingredient.scanCount == 1 ? 'scan' : 'scans'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6A5D51),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: Color(0xFF6A5D51),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _lastSeenLabel(ingredient.lastSeen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A5D51),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryIngredientEditorCard extends StatefulWidget {
  const _InventoryIngredientEditorCard({
    required this.initialIngredient,
    required this.actionLabel,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final _IngredientInventoryItem? initialIngredient;
  final String actionLabel;
  final bool isSaving;
  final ValueChanged<_InventoryIngredientDraft> onSave;
  final VoidCallback onCancel;

  @override
  State<_InventoryIngredientEditorCard> createState() =>
      _InventoryIngredientEditorCardState();
}

class _InventoryIngredientEditorCardState
    extends State<_InventoryIngredientEditorCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _expiryDateController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final ingredient = widget.initialIngredient;
    _nameController = TextEditingController(
      text: ingredient?.displayName ?? '',
    );
    _quantityController = TextEditingController(
      text: ingredient?.quantity ?? '',
    );
    _expiryDateController = TextEditingController(
      text: ingredient?.expiryDate ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  void _save() {
    if (widget.isSaving) {
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        _InventoryIngredientDraft(
          name: _nameController.text.trim(),
          quantity: _emptyToNull(_quantityController.text),
          expiryDate: _emptyToNull(_expiryDateController.text),
        ),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse(_expiryDateController.text) ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _expiryDateController.text = _dateValue(pickedDate);
    });
  }

  void _clearExpiryDate() {
    setState(() {
      _expiryDateController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.actionLabel} ingredient',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                enabled: !widget.isSaving,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ingredient name',
                  prefixIcon: Icon(Icons.restaurant_menu_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an ingredient name';
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                enabled: !widget.isSaving,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g. 2 pieces, 500g, 1 bunch',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiryDateController,
                enabled: !widget.isSaving,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Expiry date',
                  hintText: 'Pick a date',
                  prefixIcon: const Icon(Icons.event_outlined),
                  suffixIcon: _expiryDateController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear expiry date',
                          onPressed: _clearExpiryDate,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onTap: widget.isSaving ? null : _pickExpiryDate,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.isSaving ? null : widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: widget.isSaving ? null : _save,
                      child: Text(
                        widget.isSaving ? 'Saving...' : widget.actionLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientsLoading extends StatelessWidget {
  const _IngredientsLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loading saved ingredients...'),
            SizedBox(height: 14),
            LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _IngredientsError extends StatelessWidget {
  const _IngredientsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final needsSignIn = error.toString().contains('sign in');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFC85D3B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Could not load ingredients',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppButton.secondary(
              label: needsSignIn ? 'Sign in' : 'Try again',
              icon: needsSignIn ? Icons.login_rounded : Icons.refresh_rounded,
              onPressed: needsSignIn
                  ? () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.login,
                        (route) => false,
                      );
                    }
                  : onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIngredients extends StatelessWidget {
  const _EmptyIngredients();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.kitchen_outlined, color: Color(0xFFC85D3B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No ingredients saved yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Scan a shelf to build your account inventory.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: 'Start scanning',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () => showScanImagePickerOptions(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchingIngredients extends StatelessWidget {
  const _NoMatchingIngredients();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.search_off_rounded, color: Color(0xFFC85D3B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No saved ingredients match this filter.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryIngredientDraft {
  const _InventoryIngredientDraft({
    required this.name,
    required this.quantity,
    required this.expiryDate,
  });

  final String name;
  final String? quantity;
  final String? expiryDate;
}

List<_IngredientInventoryItem> _filterIngredients({
  required List<HistoryScan> scans,
  required String query,
  required _IngredientFilter filter,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final sourceScans = filter == _IngredientFilter.latest
      ? scans.isEmpty
            ? <HistoryScan>[]
            : [scans.first]
      : scans;
  final ingredients = _buildInventory(sourceScans).where((ingredient) {
    final matchesQuery = _matchesIngredientSearch(
      ingredient: ingredient,
      normalizedQuery: normalizedQuery,
    );
    final matchesFilter = switch (filter) {
      _IngredientFilter.all => true,
      _IngredientFilter.latest => true,
      _IngredientFilter.fruits => _matchesIngredientCategory(
        ingredient.name,
        _fruitKeywords,
      ),
      _IngredientFilter.vegetables => _matchesIngredientCategory(
        ingredient.name,
        _vegetableKeywords,
      ),
      _IngredientFilter.protein => _matchesIngredientCategory(
        ingredient.name,
        _proteinKeywords,
      ),
      _IngredientFilter.dairy => _matchesIngredientCategory(
        ingredient.name,
        _dairyKeywords,
      ),
      _IngredientFilter.grains => _matchesIngredientCategory(
        ingredient.name,
        _grainKeywords,
      ),
      _IngredientFilter.pantry => _matchesIngredientCategory(
        ingredient.name,
        _pantryKeywords,
      ),
      _IngredientFilter.highConfidence =>
        !ingredient.isManualOnly && ingredient.bestConfidence >= 0.75,
    };

    return matchesQuery && matchesFilter;
  }).toList();

  ingredients.sort((a, b) {
    final confidenceCompare = b.bestConfidence.compareTo(a.bestConfidence);
    if (confidenceCompare != 0) {
      return confidenceCompare;
    }

    return a.displayName.compareTo(b.displayName);
  });

  return ingredients;
}

bool _matchesIngredientSearch({
  required _IngredientInventoryItem ingredient,
  required String normalizedQuery,
}) {
  if (normalizedQuery.isEmpty) {
    return true;
  }

  final searchText =
      '${ingredient.name} ${ingredient.displayName} ${ingredient.quantity ?? ''} ${ingredient.expiryDate ?? ''}'
          .toLowerCase()
          .trim();
  final queryTerms = normalizedQuery
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty);

  return queryTerms.every(searchText.contains);
}

ScanIngredientUpdate _scanIngredientUpdate(HistoryIngredient ingredient) {
  return ScanIngredientUpdate(
    name: ingredient.name,
    confidence: ingredient.confidence,
    quantity: ingredient.quantity,
    expiryDate: ingredient.expiryDate,
  );
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _dateValue(DateTime date) {
  return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
}

Widget _inventoryPill(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F6F1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFCAD3CA)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF6A5D51),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

bool _matchesIngredientCategory(String name, Set<String> keywords) {
  final normalizedName = name.toLowerCase().trim();
  final nameWords = normalizedName
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toSet();

  return keywords.any((keyword) {
    if (keyword.contains(' ')) {
      return normalizedName.contains(keyword);
    }

    return nameWords.contains(keyword) ||
        nameWords.contains('${keyword}s') ||
        nameWords.contains('${keyword}es') ||
        (keyword.endsWith('y') &&
            nameWords.contains(
              '${keyword.substring(0, keyword.length - 1)}ies',
            ));
  });
}

_IngredientIconSpec _ingredientIconSpec(String name) {
  final normalizedName = name.toLowerCase().trim();
  final nameWords = normalizedName
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toSet();

  for (final entry in _specificIngredientIcons.entries) {
    final keyword = entry.key;
    if (keyword.contains(' ')) {
      if (normalizedName.contains(keyword)) {
        return entry.value;
      }
      continue;
    }

    if (nameWords.contains(keyword) ||
        nameWords.contains('${keyword}s') ||
        nameWords.contains('${keyword}es')) {
      return entry.value;
    }
  }

  if (_matchesIngredientCategory(name, _fruitKeywords)) {
    return _IngredientIconSpec.fruit;
  }
  if (_matchesIngredientCategory(name, _vegetableKeywords)) {
    return _IngredientIconSpec.vegetable;
  }
  if (_matchesIngredientCategory(name, _proteinKeywords)) {
    return _IngredientIconSpec.protein;
  }
  if (_matchesIngredientCategory(name, _dairyKeywords)) {
    return _IngredientIconSpec.dairy;
  }
  if (_matchesIngredientCategory(name, _grainKeywords)) {
    return _IngredientIconSpec.grain;
  }
  if (_matchesIngredientCategory(name, _pantryKeywords)) {
    return _IngredientIconSpec.pantry;
  }

  return _IngredientIconSpec.unknown;
}

class _IngredientIconSpec {
  const _IngredientIconSpec({
    required this.icon,
    required this.backgroundColor,
    required this.color,
  });

  static const fruit = _IngredientIconSpec(
    icon: Icons.spa_rounded,
    backgroundColor: Color(0xFFFFE1DE),
    color: Color(0xFFC24232),
  );

  static const vegetable = _IngredientIconSpec(
    icon: Icons.eco_rounded,
    backgroundColor: Color(0xFFDCECDF),
    color: Color(0xFF23433C),
  );

  static const protein = _IngredientIconSpec(
    icon: Icons.restaurant_menu_rounded,
    backgroundColor: Color(0xFFF4DFD4),
    color: Color(0xFF9A452C),
  );

  static const dairy = _IngredientIconSpec(
    icon: Icons.water_drop_rounded,
    backgroundColor: Color(0xFFDDEAF6),
    color: Color(0xFF315D7B),
  );

  static const grain = _IngredientIconSpec(
    icon: Icons.rice_bowl_outlined,
    backgroundColor: Color(0xFFF2E5C7),
    color: Color(0xFF7B5721),
  );

  static const pantry = _IngredientIconSpec(
    icon: Icons.kitchen_outlined,
    backgroundColor: Color(0xFFE7E2D8),
    color: Color(0xFF5F5142),
  );

  static const unknown = _IngredientIconSpec(
    icon: Icons.eco_outlined,
    backgroundColor: Color(0xFFEDE3D7),
    color: Color(0xFF23433C),
  );

  final IconData icon;
  final Color backgroundColor;
  final Color color;
}

const _eggIcon = _IngredientIconSpec(
  icon: Icons.egg_alt_outlined,
  backgroundColor: Color(0xFFFFF0C8),
  color: Color(0xFF8B6416),
);

const _fishIcon = _IngredientIconSpec(
  icon: Icons.set_meal,
  backgroundColor: Color(0xFFD7EBF3),
  color: Color(0xFF2C657D),
);

const _breadIcon = _IngredientIconSpec(
  icon: Icons.bakery_dining,
  backgroundColor: Color(0xFFF1DEC1),
  color: Color(0xFF7C5127),
);

const _noodleIcon = _IngredientIconSpec(
  icon: Icons.ramen_dining,
  backgroundColor: Color(0xFFF4DFC7),
  color: Color(0xFF8B4E28),
);

const _cheeseIcon = _IngredientIconSpec(
  icon: Icons.breakfast_dining,
  backgroundColor: Color(0xFFFFE8A8),
  color: Color(0xFF896109),
);

const _specificIngredientIcons = {
  'egg': _eggIcon,
  'fish': _fishIcon,
  'salmon': _fishIcon,
  'tuna': _fishIcon,
  'crab': _fishIcon,
  'shrimp': _fishIcon,
  'prawn': _fishIcon,
  'bread': _breadIcon,
  'flour': _breadIcon,
  'wheat': _breadIcon,
  'noodle': _noodleIcon,
  'pasta': _noodleIcon,
  'cheese': _cheeseIcon,
  'cheddar': _cheeseIcon,
  'mozzarella': _cheeseIcon,
  'parmesan': _cheeseIcon,
};

const _fruitKeywords = {
  'apple',
  'apricot',
  'avocado',
  'banana',
  'berry',
  'blackberry',
  'blueberry',
  'cherry',
  'coconut',
  'dragon fruit',
  'grape',
  'grapefruit',
  'guava',
  'kiwi',
  'lemon',
  'lime',
  'mango',
  'melon',
  'orange',
  'papaya',
  'peach',
  'pear',
  'pineapple',
  'plum',
  'pomegranate',
  'raspberry',
  'strawberry',
  'watermelon',
};

const _vegetableKeywords = {
  'asparagus',
  'beet',
  'bok choy',
  'broccoli',
  'cabbage',
  'carrot',
  'cauliflower',
  'celery',
  'chili',
  'corn',
  'cucumber',
  'eggplant',
  'garlic',
  'ginger',
  'green bean',
  'kale',
  'lettuce',
  'mushroom',
  'okra',
  'onion',
  'pea',
  'potato',
  'pumpkin',
  'radish',
  'red pepper',
  'spinach',
  'squash',
  'sweet potato',
  'tomato',
  'vegetable',
  'zucchini',
};

const _proteinKeywords = {
  'bacon',
  'beef',
  'chicken',
  'crab',
  'egg',
  'fish',
  'ham',
  'lamb',
  'meat',
  'pork',
  'prawn',
  'salmon',
  'sausage',
  'shrimp',
  'tempeh',
  'tofu',
  'tuna',
  'turkey',
};

const _dairyKeywords = {
  'butter',
  'cheddar',
  'cheese',
  'cream',
  'milk',
  'mozzarella',
  'parmesan',
  'yogurt',
};

const _grainKeywords = {
  'barley',
  'bread',
  'cereal',
  'couscous',
  'flour',
  'grain',
  'noodle',
  'oat',
  'pasta',
  'quinoa',
  'rice',
  'tortilla',
  'wheat',
};

const _pantryKeywords = {
  'almond',
  'bean',
  'chickpea',
  'honey',
  'jam',
  'ketchup',
  'lentil',
  'mayonnaise',
  'mustard',
  'nut',
  'oil',
  'sauce',
  'salt',
  'spice',
  'sugar',
  'syrup',
  'vinegar',
  'walnut',
};

List<_IngredientInventoryItem> _buildInventory(List<HistoryScan> scans) {
  final byName = <String, _MutableIngredientInventoryItem>{};

  for (final scan in scans) {
    for (final ingredient in scan.detectedIngredients) {
      final name = ingredient.name.trim().toLowerCase();
      if (name.isEmpty) {
        continue;
      }

      final item = byName.putIfAbsent(
        name,
        () => _MutableIngredientInventoryItem(name: name),
      );
      item.scanIds.add(scan.id);
      final confidence = ingredient.confidence;
      if (confidence == null) {
        item.hasManualIngredient = true;
      } else {
        item.bestConfidence = item.bestConfidence > confidence
            ? item.bestConfidence
            : confidence;
      }

      final createdDate = scan.createdDate;
      if (createdDate != null &&
          (item.lastSeen == null || createdDate.isAfter(item.lastSeen!))) {
        item.lastSeen = createdDate;
        item.quantity = ingredient.quantity;
        item.expiryDate = ingredient.expiryDate;
      } else if (item.lastSeen == null) {
        item.quantity ??= ingredient.quantity;
        item.expiryDate ??= ingredient.expiryDate;
      }
    }
  }

  return byName.values.map(_IngredientInventoryItem.fromMutable).toList();
}

String _lastSeenLabel(DateTime? date) {
  if (date == null) {
    return 'Saved scan';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final scanDay = DateTime(date.year, date.month, date.day);
  final difference = today.difference(scanDay).inDays;

  if (difference == 0) {
    return 'Seen today';
  }
  if (difference == 1) {
    return 'Seen yesterday';
  }

  return 'Seen ${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
}

String _displayName(String name) {
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class _MutableIngredientInventoryItem {
  _MutableIngredientInventoryItem({required this.name});

  final String name;
  final Set<String> scanIds = {};
  double bestConfidence = 0;
  bool hasManualIngredient = false;
  DateTime? lastSeen;
  String? quantity;
  String? expiryDate;
}

class _IngredientInventoryItem {
  const _IngredientInventoryItem({
    required this.name,
    required this.displayName,
    required this.scanIds,
    required this.bestConfidence,
    required this.hasManualIngredient,
    required this.lastSeen,
    required this.quantity,
    required this.expiryDate,
  });

  factory _IngredientInventoryItem.fromMutable(
    _MutableIngredientInventoryItem item,
  ) {
    return _IngredientInventoryItem(
      name: item.name,
      displayName: _displayName(item.name),
      scanIds: Set.unmodifiable(item.scanIds),
      bestConfidence: item.bestConfidence.clamp(0, 1),
      hasManualIngredient: item.hasManualIngredient,
      lastSeen: item.lastSeen,
      quantity: item.quantity,
      expiryDate: item.expiryDate,
    );
  }

  final String name;
  final String displayName;
  final Set<String> scanIds;
  final double bestConfidence;
  final bool hasManualIngredient;
  final DateTime? lastSeen;
  final String? quantity;
  final String? expiryDate;

  int get scanCount => scanIds.length;
  int get confidencePercent => (bestConfidence * 100).round();
  bool get isManualOnly => hasManualIngredient && bestConfidence <= 0;
  String get confidenceLabel => isManualOnly ? 'Man.' : '$confidencePercent%';
}
