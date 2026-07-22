// core/widget/photo/photo_grid.dart
import 'dart:io';
import 'package:flutter/material.dart';

import '../../Services/Photos.dart';

class PhotoGrid extends StatelessWidget {
  final List<String> photoNames;
  final Function(int) onDelete;
  final bool isEditMode;

  const PhotoGrid({
    super.key,
    required this.photoNames,
    required this.onDelete,
    this.isEditMode = true,
  });

  @override
  Widget build(BuildContext context) {
    if (photoNames.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Aucune photo'),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photoNames.length,
        itemBuilder: (context, index) {
          return FutureBuilder<File?>(
            future: PhotoService.getPhotoFile(photoNames[index]),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return _buildPhotoItem(snapshot.data!.path, index);
              } else if (snapshot.hasError) {
                return _buildErrorItem(index);
              }
              return _buildLoadingItem();
            },
          );
        },
      ),
    );
  }

  Widget _buildPhotoItem(String path, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              width: 100,
              height: 100,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            ),
          ),
          if (isEditMode)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onDelete(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorItem(int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}