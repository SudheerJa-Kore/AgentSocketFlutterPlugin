import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _cardWidth = 200.0;
const _imageHeight = 120.0;
const _contentPadding = 12.0;
const _contentWidth = _cardWidth - (_contentPadding * 2);

const _titleStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  height: 1.2,
  color: Colors.black87,
);

/// Horizontal carousel of property/listing cards from rich content payloads.
class CarouselMessage extends StatelessWidget {
  final Carousel carousel;
  final double borderRadius;

  const CarouselMessage({
    super.key,
    required this.carousel,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (carousel.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardHeight = _maxCardHeight(carousel.cards);
    final subtitleStyle = TextStyle(
      fontSize: 12,
      height: 1.35,
      color: Colors.grey.shade700,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < carousel.cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _CarouselCard(
              card: carousel.cards[i],
              borderRadius: borderRadius,
              height: cardHeight,
              subtitleStyle: subtitleStyle,
            ),
          ],
        ],
      ),
    );
  }

  static double _maxCardHeight(List<CarouselCard> cards) {
    var maxHeight = 0.0;

    for (final card in cards) {
      final height = _measureCardHeight(card);
      if (height > maxHeight) {
        maxHeight = height;
      }
    }

    return maxHeight;
  }

  static double _measureCardHeight(CarouselCard card) {
    var height = _contentPadding * 2;

    if (_safeUrl(card.imageUrl) != null) {
      height += _imageHeight;
    }

    height += _measureText(card.title, _titleStyle, 2);

    if (card.subtitle != null && card.subtitle!.isNotEmpty) {
      height += 4;
      height += _measureText(
        card.subtitle!,
        TextStyle(fontSize: 12, height: 1.35),
        3,
      );
    }

    return height;
  }

  static double _measureText(
    String text,
    TextStyle style,
    int maxLines,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _contentWidth);

    return painter.height;
  }

  static String? _safeUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      return null;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }
    return uri.toString();
  }
}

class _CarouselCard extends StatelessWidget {
  final CarouselCard card;
  final double borderRadius;
  final double height;
  final TextStyle subtitleStyle;

  const _CarouselCard({
    required this.card,
    required this.borderRadius,
    required this.height,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final actionUrl = CarouselMessage._safeUrl(card.defaultActionUrl);
    final imageUrl = CarouselMessage._safeUrl(card.imageUrl);

    return SizedBox(
      width: _cardWidth,
      height: height,
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: actionUrl != null ? () => _openUrl(actionUrl) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  height: _imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: _imageHeight,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported, color: Colors.grey.shade500),
                  ),
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(_contentPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _titleStyle,
                        ),
                        if (card.subtitle != null && card.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            card.subtitle!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
