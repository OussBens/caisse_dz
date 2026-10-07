import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../../../Services/Photos.dart';
import '../../theme/app_style.dart';

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
  bool _isHoveredAdd = false;
  bool _isHoveredDelete = false;

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

        // Copier vers un chemin temporaire absolu (dossier temp système,
        // toujours accessible en écriture — voir PhotoService.buildTempPhotoPath).
        final tempPath = PhotoService.buildTempPhotoPath(path.extension(file.path));
        final tempFile = await file.copy(tempPath);

        // Si on est en mode édition et qu'il y a une ancienne photo, on la marque pour suppression
        if (widget.isEditMode && _currentPhoto != null) {
          // L'ancienne photo sera supprimée lors de la sauvegarde
          debugPrint('📸 Remplacement de la photo: $_currentPhoto -> $tempPath');
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
    if (_currentPhoto != null && widget.isEditMode && !PhotoService.isTempPhoto(_currentPhoto)) {
      await PhotoService.deletePhoto(_currentPhoto);
    } else if (_currentPhoto != null && PhotoService.isTempPhoto(_currentPhoto)) {
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

        // Boutons d'ajout/suppression — même langage visuel (violet/crevette,
        // survol avec légère élévation) que MainButton ailleurs dans l'app,
        // au lieu du gris/rouge générique d'origine.
        Row(
          children: [
            Expanded(
              child: _photoActionButton(
                onTap: _isLoading ? null : _addPhoto,
                isHovered: _isHoveredAdd,
                onHoverChanged: (v) => setState(() => _isHoveredAdd = v),
                color: Appstyle.violet,
                backgroundColor: Appstyle.violetC,
                icon: _currentPhoto == null ? Icons.add_photo_alternate : Icons.edit,
                label: _currentPhoto == null ? 'Ajouter une photo' : 'Changer la photo',
                loading: _isLoading,
              ),
            ),
            if (_currentPhoto != null && _currentPhoto!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _photoActionButton(
                  onTap: _removePhoto,
                  isHovered: _isHoveredDelete,
                  onHoverChanged: (v) => setState(() => _isHoveredDelete = v),
                  color: Appstyle.crevete,
                  backgroundColor: Appstyle.crevete.withOpacity(0.08),
                  icon: Icons.delete_outline,
                  label: 'Supprimer',
                  horizontalPadding: 20,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _photoActionButton({
    required VoidCallback? onTap,
    required bool isHovered,
    required ValueChanged<bool> onHoverChanged,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
    required String label,
    bool loading = false,
    double horizontalPadding = 0,
  }) {
    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..translate(0.0, isHovered ? -2.0 : 0.0),
          transformAlignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            border: Border.all(color: color.withOpacity(isHovered ? 0.6 : 0.3), width: 1.5),
            boxShadow: isHovered ? Appstyle.shadowHover(color: color) : const [],
          ),
          child: loading
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(label, style: Appstyle.textSB.copyWith(color: color)),
            ],
          ),
        ),
      ),
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
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
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
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: 160,
                ),
              ),
            ),
          );
        }

        return Container(
          height: 160,
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