import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

class ArticleCard extends StatelessWidget {
  final String category;
  final String title;
  final String author;
  final String date;
  final String imageUrl;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.category,
    required this.title,
    required this.author,
    required this.date,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final web = WoofCareWebDesign.enabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(web ? 12 : 18),
        onTap: onTap,
        child: Container(
          height: 193,
          padding: EdgeInsets.fromLTRB(
            web ? 14 : 16,
            web ? 14 : 20,
            web ? 16 : 16,
            web ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: web
                ? WoofCareWebDesign.surface
                : WoofCareColors.secondaryBackground,
            borderRadius: BorderRadius.circular(web ? 12 : 18),
            border: web ? Border.all(color: WoofCareWebDesign.border) : null,
            boxShadow: web
                ? WoofCareWebDesign.cardShadow
                : [
                    BoxShadow(
                      color: WoofCareColors.cardShadow,
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
          ),
          child: Row(
            children: [
              _ArticleImage(imageUrl: imageUrl),
              SizedBox(width: web ? 16 : 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: web ? 8 : 0,
                        vertical: web ? 4 : 0,
                      ),
                      decoration: web
                          ? BoxDecoration(
                              color: WoofCareWebDesign.primary.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            )
                          : null,
                      child: Text(
                        web ? category.toUpperCase() : category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: web ? 10 : 14,
                          letterSpacing: web ? 0.7 : 0,
                          color: web
                              ? WoofCareWebDesign.primary
                              : WoofCareColors.buttonColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: web ? 10 : 12),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: web ? 17 : 20,
                        height: web ? 1.3 : 1.35,
                        fontWeight: web ? FontWeight.w600 : FontWeight.w800,
                        color: web
                            ? WoofCareWebDesign.text
                            : WoofCareColors.primaryTextAndIcons,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: web ? 15 : 18,
                          color: web
                              ? WoofCareWebDesign.textMuted
                              : WoofCareColors.buttonColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: web ? 12 : 13,
                              color: web
                                  ? WoofCareWebDesign.textMuted
                                  : WoofCareColors.buttonColor,
                              fontWeight: web
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: web
                                ? WoofCareWebDesign.textMuted
                                : WoofCareColors.buttonColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleImage extends StatelessWidget {
  final String imageUrl;

  const _ArticleImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final web = WoofCareWebDesign.enabled;

    return ClipRRect(
      borderRadius: BorderRadius.circular(web ? 8 : 22),
      child: SizedBox(
        width: web ? 124 : 136,
        height: web ? 163 : 154,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: WoofCareColors.buttonColor,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const _ArticleImageFallback();
                },
              )
            : const _ArticleImageFallback(),
      ),
    );
  }
}

class _ArticleImageFallback extends StatelessWidget {
  const _ArticleImageFallback();

  @override
  Widget build(BuildContext context) {
    final web = WoofCareWebDesign.enabled;
    return Container(
      color: web
          ? WoofCareWebDesign.surfaceMuted
          : WoofCareColors.buttonColor.withValues(alpha: 0.1),
      child: Icon(
        web ? Icons.image_outlined : Icons.pets,
        size: web ? 34 : 56,
        color: web ? WoofCareWebDesign.textMuted : WoofCareColors.buttonColor,
      ),
    );
  }
}
