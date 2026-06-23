/// Rich content payloads attached to assistant messages.
library;

class CarouselCard {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? defaultActionUrl;

  const CarouselCard({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.defaultActionUrl,
  });

  factory CarouselCard.fromJson(Map<String, dynamic> json) {
    return CarouselCard(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String?,
      defaultActionUrl: json['default_action_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (imageUrl != null) 'image_url': imageUrl,
      if (defaultActionUrl != null) 'default_action_url': defaultActionUrl,
    };
  }
}

class Carousel {
  final List<CarouselCard> cards;

  const Carousel({required this.cards});

  factory Carousel.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'];
    if (cardsRaw is! List) {
      return const Carousel(cards: []);
    }

    final cards = <CarouselCard>[];
    for (final item in cardsRaw) {
      if (item is Map<String, dynamic> && (item['title'] as String?)?.isNotEmpty == true) {
        cards.add(CarouselCard.fromJson(item));
      }
    }
    return Carousel(cards: cards);
  }

  Map<String, dynamic> toJson() {
    return {
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }
}

class RichContent {
  final Carousel? carousel;

  const RichContent({this.carousel});

  bool get hasRenderableContent =>
      carousel != null && carousel!.cards.isNotEmpty;

  factory RichContent.fromJson(Map<String, dynamic> json) {
    final carouselRaw = json['carousel'];
    return RichContent(
      carousel: carouselRaw is Map<String, dynamic>
          ? Carousel.fromJson(carouselRaw)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (carousel != null) 'carousel': carousel!.toJson(),
    };
  }
}

RichContent? parseRichContent(dynamic raw) {
  if (raw is! Map<String, dynamic>) {
    return null;
  }
  final parsed = RichContent.fromJson(raw);
  return parsed.hasRenderableContent ? parsed : null;
}
