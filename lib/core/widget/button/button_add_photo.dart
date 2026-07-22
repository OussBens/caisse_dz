import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../../../Services/Photos.dart';

class ButtonAddPhoto extends StatefulWidget {
  final String? photo;
  final Function(String?) onPhotoChanged;
  final bool isEditMode;

  const ButtonAddPhoto({
    super.key,
    required this.photo,
    required this.onPhotoChanged,
    this.isEditMode = false,
  });

  @override
  State<ButtonAddPhoto> createState() => _ButtonAddPhotoState();
}

class _ButtonAddPhotoState extends State<ButtonAddPhoto> {
  bool _isLoading = false;
  String? _currentPhoto;

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.photo;
  }

  @override
  void didUpdateWidget(ButtonAddPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo != widget.photo) {
      _currentPhoto = widget.photo;
    }
  }

  // ✅ AJOUTER CETTE MÉTHODE
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addPhoto() async {
    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);

        // Générer un nom temporaire unique
        final tempName = 'temp_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
        final tempFile = await file.copy(tempName);

        // Si on est en mode édition et qu'il y a une ancienne photo, on la marque pour suppression
        if (widget.isEditMode && _currentPhoto != null) {
          // L'ancienne photo sera supprimée lors de la sauvegarde
          debugPrint('📸 Remplacement de la photo: $_currentPhoto -> $tempName');
        }

        _currentPhoto = tempFile.path;
        widget.onPhotoChanged(_currentPhoto);
        _showSnackBar('Photo ajoutée avec succès');
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
      debugPrint('Erreur sélection photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removePhoto() async {
    if (_currentPhoto != null && widget.isEditMode && !_currentPhoto!.startsWith('temp_')) {
      await PhotoService.deletePhoto(_currentPhoto);
    } else if (_currentPhoto != null && _currentPhoto!.startsWith('temp_')) {
      try {
        final tempFile = File(_currentPhoto!);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('Erreur suppression fichier temporaire: $e');
      }
    }

    _currentPhoto = null;
    widget.onPhotoChanged(null);
    _showSnackBar('Photo supprimée');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Affichage de la photo existante
        if (_currentPhoto != null && _currentPhoto!.isNotEmpty)
          _buildPhotoItem(_currentPhoto!),

        const SizedBox(height: 12),

        // Boutons d'ajout/suppression
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _addPhoto,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_currentPhoto == null ? Icons.add_photo_alternate : Icons.edit,
                          size: 32, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        _currentPhoto == null ? 'Ajouter une photo' : 'Changer la photo',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_currentPhoto != null && _currentPhoto!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: _removePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!, width: 1.5),
                    ),
                    child: Icon(Icons.delete, color: Colors.red[600]),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoItem(String photoName) {
    return FutureBuilder<File?>(
      future: PhotoService.getPhotoFile(photoName),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return GestureDetector(
            onTap: () => _showFullScreenPhoto(context, snapshot.data!.path),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
            ),
          );
        }

        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: snapshot.hasError
                ? Icon(Icons.broken_image, color: Colors.grey[400], size: 48)
                : const CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  void _showFullScreenPhoto(BuildContext context, String photoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}