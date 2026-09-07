import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/api_constants.dart';
import '../utils/app_colors.dart';

/// Component avatar toàn diện, tự động xử lý mọi dạng đường dẫn ảnh:
/// - URL đầy đủ (Cloudinary, S3, Firebase, server ngoài...)
/// - Giao thức // (protocol-relative)
/// - Đường dẫn tương đối (/uploads/..., uploads/...)
/// - Ảnh vector SVG (Dicebear, file .svg)
/// - Data URI (Base64 hoặc SVG inline)
/// - Fallback sang CircleAvatar chữ cái viết tắt gradient khi không có ảnh hoặc lỗi mạng.
class AppAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Widget? badge;

  const AppAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.radius = 28,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.border,
    this.boxShadow,
    this.badge,
  });

  /// Chuẩn hóa URL từ DB thành URL mạng hợp lệ
  static String? resolveAvatarUrl(String? raw) {
    if (raw == null) return null;
    var url = raw.trim();
    if (url.isEmpty ||
        url.toLowerCase() == 'null' ||
        url.toLowerCase() == 'undefined') {
      return null;
    }

    // Nếu là đối tượng JSON (ví dụ Cloudinary lưu dạng chuỗi JSON)
    if (url.startsWith('{') && url.endsWith('}')) {
      try {
        final decoded = jsonDecode(url);
        if (decoded is Map) {
          final extracted = decoded['url']?.toString() ??
              decoded['secure_url']?.toString() ??
              decoded['link']?.toString() ??
              decoded['path']?.toString();
          if (extracted != null && extracted.isNotEmpty) {
            url = extracted.trim();
          }
        }
      } catch (_) {}
    }

    // Data URI (base64 hoặc svg)
    if (url.startsWith('data:')) {
      return url;
    }

    // Protocol-relative URL: //domain.com/path
    if (url.startsWith('//')) {
      return 'https:$url';
    }

    // Đường dẫn tương đối: /uploads/abc.png hoặc uploads/abc.png
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
      if (url.startsWith('/')) {
        url = '$base$url';
      } else {
        url = '$base/$url';
      }
    }

    // Xử lý localhost/127.0.0.1 nếu server deploy ở nơi khác
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      try {
        final uri = Uri.parse(url);
        final baseUri = Uri.parse(ApiConstants.baseUrl);
        if (!baseUri.host.contains('localhost') &&
            !baseUri.host.contains('127.0.0.1')) {
          url = uri
              .replace(
                scheme: baseUri.scheme,
                host: baseUri.host,
                port: baseUri.hasPort ? baseUri.port : null,
              )
              .toString();
        }
      } catch (_) {}
    }

    try {
      return Uri.encodeFull(url);
    } catch (_) {
      return url;
    }
  }

  /// Kiểm tra ảnh có phải định dạng vector SVG hay không
  static bool isSvg(String url) {
    final lower = url.toLowerCase();
    if (lower.startsWith('data:image/svg+xml')) return true;
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? lower;
    return path.endsWith('.svg') ||
        lower.contains('dicebear.com') ||
        lower.contains('/svg');
  }

  /// Lấy chữ cái viết tắt từ họ tên
  static String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'NV';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NV';
    if (parts.length == 1) {
      final word = parts[0];
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }
    // Lấy chữ đầu của từ đầu và chữ đầu của từ cuối (Ví dụ: Nguyễn Sơn Tùng -> NT)
    final firstChar = parts.first.substring(0, 1);
    final lastChar = parts.last.substring(0, 1);
    return '$firstChar$lastChar'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = resolveAvatarUrl(avatarUrl);
    final initials = getInitials(name);
    final size = radius * 2;
    final fSize = fontSize ?? (radius * 0.75);

    Widget avatarContent;
    if (cleanUrl == null) {
      avatarContent = _buildFallback(initials, fSize);
    } else if (cleanUrl.startsWith('data:image/svg+xml')) {
      avatarContent = _buildDataSvg(cleanUrl, initials, fSize);
    } else if (cleanUrl.startsWith('data:image/')) {
      avatarContent = _buildDataRaster(cleanUrl, initials, fSize);
    } else if (isSvg(cleanUrl)) {
      avatarContent = _buildNetworkSvg(cleanUrl, initials, fSize);
    } else {
      avatarContent = _buildCachedNetworkImage(cleanUrl, initials, fSize);
    }

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
        boxShadow: boxShadow,
      ),
      child: ClipOval(
        // Giữ CircleAvatar trong cây widget để tương thích tuyệt đối với các test hiện có
        child: CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.transparent,
          child: SizedBox(
            width: size,
            height: size,
            child: avatarContent,
          ),
        ),
      ),
    );

    if (badge != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: badge!,
          ),
        ],
      );
    }

    return avatarWidget;
  }

  Widget _buildFallback(String initials, double fSize) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? AppColors.primaryBlue,
            const Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fSize,
          fontWeight: FontWeight.w700,
          color: textColor ?? Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDataSvg(String dataUrl, String initials, double fSize) {
    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex != -1) {
        final content = dataUrl.substring(commaIndex + 1);
        final isBase64 = dataUrl.substring(0, commaIndex).contains(';base64');
        final svgString = isBase64 ? utf8.decode(base64Decode(content)) : Uri.decodeComponent(content);
        return SvgPicture.string(
          svgString,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _buildFallback(initials, fSize),
        );
      }
    } catch (_) {}
    return _buildFallback(initials, fSize);
  }

  Widget _buildDataRaster(String dataUrl, String initials, double fSize) {
    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex != -1) {
        final bytes = base64Decode(dataUrl.substring(commaIndex + 1));
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(initials, fSize),
        );
      }
    } catch (_) {}
    return _buildFallback(initials, fSize);
  }

  Widget _buildNetworkSvg(String url, String initials, double fSize) {
    return SvgPicture.network(
      url,
      fit: BoxFit.cover,
      placeholderBuilder: (_) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      // Khi load SVG lỗi sẽ hiển thị fallback initials
      errorBuilder: (_, __, ___) => _buildFallback(initials, fSize),
    );
  }

  Widget _buildCachedNetworkImage(String url, String initials, double fSize) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => _buildFallback(initials, fSize),
    );
  }
}
