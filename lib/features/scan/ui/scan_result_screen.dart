import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/core/widgets/section_title.dart';
import 'package:lazychef/features/scan/data/scan_repository.dart';
import 'package:lazychef/features/scan/models/scan_image_selection.dart';
import 'package:lazychef/features/scan/models/scan_upload_result.dart';
import 'package:lazychef/features/scan/providers/scan_provider.dart';

class ScanResultScreen extends ConsumerWidget {
  const ScanResultScreen({super.key, this.selection});

  final ScanImageSelection? selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImage = selection;
    final scanUpload = selectedImage == null
        ? null
        : ref.watch(scanUploadProvider(selectedImage));

    return LazyChefScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.history);
                  },
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('History'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SectionTitle(
              eyebrow: 'Scan result',
              title: 'Your fridge looks promising',
              subtitle: 'Review and adjust detected ingredients before use.',
            ),
            const SizedBox(height: 18),
            if (selectedImage != null) ...[
              _SelectedImagePreview(selection: selectedImage),
              const SizedBox(height: 18),
            ],
            if (selectedImage == null)
              const _NoScanContent()
            else
              scanUpload!.when(
                loading: () => const _ScanUploadLoading(),
                error: (error, _) => _ScanUploadError(
                  error: error,
                  onRetry: () {
                    ref.invalidate(scanUploadProvider(selectedImage));
                  },
                ),
                data: (result) => _UploadedScanContent(result: result),
              ),
            const SizedBox(height: 8),
            AppButton.primary(
              label: 'Open history',
              icon: Icons.bookmark_added_outlined,
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.history);
              },
            ),
            const SizedBox(height: 12),
            AppButton.secondary(
              label: 'Scan another shelf',
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.home,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoScanContent extends StatelessWidget {
  const _NoScanContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScanSummaryCard(
          eyebrow: 'No image selected',
          title: 'Choose a fridge photo before viewing scan results.',
          icon: Icons.add_photo_alternate_outlined,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'Start a new scan from the home screen to upload an image and run ingredient detection.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6A5D51)),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _UploadedScanContent extends ConsumerStatefulWidget {
  const _UploadedScanContent({required this.result});

  final ScanUploadResult result;

  @override
  ConsumerState<_UploadedScanContent> createState() =>
      _UploadedScanContentState();
}

class _UploadedScanContentState extends ConsumerState<_UploadedScanContent> {
  late List<_EditableIngredient> _ingredients;
  int? _activeEditorIndex;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ingredients = _editableIngredientsFromResult();
  }

  @override
  void didUpdateWidget(covariant _UploadedScanContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.result.scan.id != widget.result.scan.id) {
      _ingredients = _editableIngredientsFromResult();
      _activeEditorIndex = null;
      _hasUnsavedChanges = false;
      _isSaving = false;
    }
  }

  List<_EditableIngredient> _editableIngredientsFromResult() {
    return widget.result.analysis.detectedIngredients
        .map(_EditableIngredient.fromDetected)
        .toList();
  }

  void _startAddingIngredient() {
    setState(() {
      _activeEditorIndex = -1;
    });
  }

  void _startEditingIngredient(int index) {
    setState(() {
      _activeEditorIndex = index;
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _hasUnsavedChanges = true;

      final activeEditorIndex = _activeEditorIndex;
      if (activeEditorIndex == index) {
        _activeEditorIndex = null;
      } else if (activeEditorIndex != null && activeEditorIndex > index) {
        _activeEditorIndex = activeEditorIndex - 1;
      }
    });
  }

  void _saveIngredientDraft(_IngredientDraft draft) {
    final activeEditorIndex = _activeEditorIndex;
    if (activeEditorIndex == null) {
      return;
    }

    setState(() {
      if (activeEditorIndex == -1) {
        _ingredients.add(_EditableIngredient.manual(draft));
      } else if (activeEditorIndex < _ingredients.length) {
        final ingredient = _ingredients[activeEditorIndex];
        _ingredients[activeEditorIndex] = ingredient.copyWith(
          name: draft.name,
          quantity: draft.quantity,
          expiryDate: draft.expiryDate,
        );
      }

      _activeEditorIndex = null;
      _hasUnsavedChanges = true;
    });
  }

  void _cancelIngredientEditor() {
    setState(() {
      _activeEditorIndex = null;
    });
  }

  Future<void> _saveIngredientChanges() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(scanRepositoryProvider)
          .updateScanIngredients(
            scanId: widget.result.scan.id,
            ingredients: _ingredients
                .map(
                  (ingredient) => ScanIngredientUpdate(
                    name: ingredient.name,
                    confidence: ingredient.confidence,
                    quantity: ingredient.quantity,
                    expiryDate: ingredient.expiryDate,
                  ),
                )
                .toList(),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _hasUnsavedChanges = false;
      });
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientCount = _ingredients.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScanSummaryCard(
          eyebrow: ingredientCount == 1
              ? '1 ingredient ready'
              : '$ingredientCount ingredients ready',
          title: switch (widget.result.analysis.status) {
            'failed' => 'Image uploaded. AI analysis needs attention.',
            'pending' => 'Image uploaded. AI analysis is pending.',
            _ => 'Image uploaded, analyzed, and saved.',
          },
          icon: Icons.cloud_done_rounded,
        ),
        const SizedBox(height: 16),
        // _UploadDetailsCard(result: widget.result),
        const SizedBox(height: 28),
        SectionTitle(
          eyebrow: 'Detected ingredients',
          title: 'Review your inventory',
          subtitle:
              'Change ingredients, quantity, and expiry date before recipe ranking.',
          action: FilledButton.icon(
            onPressed: _startAddingIngredient,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
        ),
        const SizedBox(height: 14),
        if (_activeEditorIndex != null) ...[
          _IngredientEditorCard(
            key: ValueKey(_activeEditorKey),
            initialIngredient: _activeEditorInitialIngredient,
            actionLabel: _activeEditorIndex == -1 ? 'Add' : 'Save',
            onSave: _saveIngredientDraft,
            onCancel: _cancelIngredientEditor,
          ),
          const SizedBox(height: 12),
        ],
        if (_ingredients.isEmpty && _activeEditorIndex == null)
          _EmptyIngredientsCard(analysis: widget.result.analysis)
        else
          ..._ingredients.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DetectedIngredientTile(
                ingredient: entry.value,
                onEdit: () => _startEditingIngredient(entry.key),
                onRemove: () => _removeIngredient(entry.key),
              ),
            ),
          ),
        if (_hasUnsavedChanges || _isSaving) ...[
          const SizedBox(height: 4),
          AppButton.primary(
            label: _isSaving ? 'Saving changes...' : 'Save changes',
            icon: Icons.save_outlined,
            onPressed: _isSaving
                ? () {}
                : () {
                    _saveIngredientChanges();
                  },
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 18),
        const SectionTitle(
          eyebrow: 'Recipe suggestions',
          title: 'Waiting for recipe generation',
          subtitle:
              'This will be connected after the AI ingredient response is real.',
        ),
      ],
    );
  }

  _EditableIngredient? get _activeEditorInitialIngredient {
    final activeEditorIndex = _activeEditorIndex;
    if (activeEditorIndex == null ||
        activeEditorIndex == -1 ||
        activeEditorIndex >= _ingredients.length) {
      return null;
    }

    return _ingredients[activeEditorIndex];
  }

  String get _activeEditorKey {
    final activeEditorIndex = _activeEditorIndex;
    if (activeEditorIndex == null ||
        activeEditorIndex == -1 ||
        activeEditorIndex >= _ingredients.length) {
      return 'add';
    }

    return 'edit-$activeEditorIndex-${_ingredients[activeEditorIndex].name}';
  }
}

class _ScanUploadLoading extends StatelessWidget {
  const _ScanUploadLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScanSummaryCard(
          eyebrow: 'Uploading scan',
          title: 'Uploading image...',
          icon: Icons.sync_rounded,
        ),
        SizedBox(height: 16),
        LinearProgressIndicator(),
        SizedBox(height: 28),
      ],
    );
  }
}

class _ScanUploadError extends StatelessWidget {
  const _ScanUploadError({required this.error, required this.onRetry});

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
                    'Scan upload failed',
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

class _ScanSummaryCard extends StatelessWidget {
  const _ScanSummaryCard({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC85D3B), Color(0xFFE2A13B)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

// class _UploadDetailsCard extends StatelessWidget {
//   const _UploadDetailsCard({required this.result});

//   final ScanUploadResult result;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Cloudinary upload',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               result.image.secureUrl,
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6A5D51)),
//             ),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: [
//                 _metadataPill(result.image.format.toUpperCase()),
//                 _metadataPill('${result.image.width} x ${result.image.height}'),
//                 _metadataPill('${(result.image.bytes / 1024).round()} KB'),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _EmptyIngredientsCard extends StatelessWidget {
  const _EmptyIngredientsCard({required this.analysis});

  final VisionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${analysis.model} analysis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              analysis.message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6A5D51)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({required this.selection});

  final ScanImageSelection selection;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = selection.source == ImageSource.camera
        ? 'Camera photo'
        : 'Gallery photo';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: FutureBuilder<Uint8List>(
              future: selection.image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return GestureDetector(
                    onTap: () {
                      _openFullImage(context, snapshot.data!);
                    },
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const ColoredBox(
                    color: Color(0xFFEADBC9),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 36),
                    ),
                  );
                }

                return const ColoredBox(
                  color: Color(0xFFEADBC9),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.image_search_rounded,
                  color: Color(0xFFC85D3B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$sourceLabel selected for ingredient detection',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullImage(BuildContext context, Uint8List imageBytes) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullImageViewer(imageBytes: imageBytes),
      ),
    );
  }
}

class _FullImageViewer extends StatelessWidget {
  const _FullImageViewer({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Center(child: Image.memory(imageBytes, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

class _DetectedIngredientTile extends StatelessWidget {
  const _DetectedIngredientTile({
    required this.ingredient,
    required this.onEdit,
    required this.onRemove,
  });

  final _EditableIngredient ingredient;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final confidence = ingredient.confidence;
    final confidenceLabel = confidence == null
        ? 'Manual'
        : '${(confidence * 100).round()}%';
    final quantity = ingredient.quantity?.trim();
    final expiryDate = ingredient.expiryDate?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metadataPill(confidenceLabel),
                      if (quantity != null && quantity.isNotEmpty)
                        _metadataPill(quantity),
                      if (expiryDate != null && expiryDate.isNotEmpty)
                        _metadataPill('Expires $expiryDate'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit inventory item',
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove ingredient',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFC85D3B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientEditorCard extends StatefulWidget {
  const _IngredientEditorCard({
    required this.initialIngredient,
    required this.actionLabel,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final _EditableIngredient? initialIngredient;
  final String actionLabel;
  final ValueChanged<_IngredientDraft> onSave;
  final VoidCallback onCancel;

  @override
  State<_IngredientEditorCard> createState() => _IngredientEditorCardState();
}

class _IngredientEditorCardState extends State<_IngredientEditorCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _expiryDateController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final ingredient = widget.initialIngredient;
    _nameController = TextEditingController(text: ingredient?.name ?? '');
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
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        _IngredientDraft(
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
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ingredient name',
                  prefixIcon: Icon(Icons.restaurant_menu_rounded),
                ),
                textInputAction: TextInputAction.done,
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
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g. 2 pieces, 500g, 1 bunch',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiryDateController,
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
                onTap: _pickExpiryDate,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(widget.actionLabel),
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

class _IngredientDraft {
  const _IngredientDraft({
    required this.name,
    required this.quantity,
    required this.expiryDate,
  });

  final String name;
  final String? quantity;
  final String? expiryDate;
}

class _EditableIngredient {
  const _EditableIngredient({
    required this.name,
    required this.confidence,
    required this.quantity,
    required this.expiryDate,
  });

  factory _EditableIngredient.fromDetected(DetectedIngredient ingredient) {
    return _EditableIngredient(
      name: _cleanIngredientName(ingredient.name),
      confidence: ingredient.confidence,
      quantity: ingredient.quantity,
      expiryDate: ingredient.expiryDate,
    );
  }

  factory _EditableIngredient.manual(_IngredientDraft draft) {
    return _EditableIngredient(
      name: draft.name,
      confidence: null,
      quantity: draft.quantity,
      expiryDate: draft.expiryDate,
    );
  }

  final String name;
  final double? confidence;
  final String? quantity;
  final String? expiryDate;

  _EditableIngredient copyWith({
    String? name,
    String? quantity,
    String? expiryDate,
  }) {
    return _EditableIngredient(
      name: name ?? this.name,
      confidence: confidence,
      quantity: quantity,
      expiryDate: expiryDate,
    );
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _cleanIngredientName(String value) {
  return value
      .replaceAll(RegExp(r'''["'`“”‘’]+'''), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _dateValue(DateTime date) {
  return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

Widget _metadataPill(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFCAD3CA)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2D241D),
      ),
    ),
  );
}
