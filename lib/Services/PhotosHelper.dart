import 'package:flutter/material.dart';
import 'Photos.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class PhotoHelper {
  static Future<ImageProvider> getProductPhotoProvider(String photoName) async {
    if (photoName.isEmpty) {
      return const AssetImage('assets/icons/default_product.png');
    }

    try {
      final file = await PhotoService.getPhotoFile(photoName);
      if (file != null && await file.exists()) {
        return FileImage(file);
      }
    } catch (e) {
      debugPrint('Erreur chargement photo: $e');
    }

    return const AssetImage('assets/icons/default_product.png');
  }

  static Widget buildProductPhoto(String photoName, {double size = 50}) {
    return FutureBuilder<ImageProvider>(
      future: getProductPhotoProvider(photoName),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: snapshot.data,
            child: photoName.isEmpty
                ? Icon(Icons.image_not_supported, size: size * 0.5)
                : null,
          );
        }

        return CircleAvatar(
          radius: size / 2,
          backgroundColor: Appstyle.neutral150,
          child: Icon(Icons.image, size: size * 0.5, color: Appstyle.neutral300),
        );
      },
    );
  }
}