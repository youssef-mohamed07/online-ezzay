import 'package:flutter/material.dart';

/// تكوين الـ Image Cache لتحسين أداء تحميل الصور
class ImageCacheConfig {
  static void configure() {
    // زيادة حجم الـ cache للصور في الذاكرة
    PaintingBinding.instance.imageCache.maximumSize = 200; // default is 1000
    
    // زيادة حجم الـ cache بالبايتات (100 MB)
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
  }
  
  /// مسح الـ cache عند الحاجة
  static void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
