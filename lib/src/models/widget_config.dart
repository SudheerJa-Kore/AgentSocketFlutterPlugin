/// Server-provided widget configuration models.
///
/// The SDK init/refresh response may include a `widgetConfig` object that the
/// host application can use to theme its chat UI. Parsing is lenient: unknown
/// or missing fields are ignored, and the original payload is always retained
/// in [WidgetConfig.raw] / [WidgetTheme.raw] for forward compatibility.
library;

/// Top-level widget configuration returned by the runtime.
class WidgetConfig {
  final WidgetTheme? theme;
  final String? themeId;
  final String? themeName;
  final String? welcomeMessage;
  final String? placeholderText;
  final String? launcherWelcomeMessage;
  final String? connectingStatusText;

  /// The original, unmodified `widgetConfig` payload.
  final Map<String, dynamic> raw;

  const WidgetConfig({
    this.theme,
    this.themeId,
    this.themeName,
    this.welcomeMessage,
    this.placeholderText,
    this.launcherWelcomeMessage,
    this.connectingStatusText,
    this.raw = const {},
  });

  factory WidgetConfig.fromMap(Map<String, dynamic> map) {
    final themeMap = map['theme'];
    return WidgetConfig(
      theme: themeMap is Map<String, dynamic>
          ? WidgetTheme.fromMap(themeMap)
          : null,
      themeId: _asString(map['themeId']),
      themeName: _asString(map['themeName']),
      welcomeMessage: _asString(map['welcomeMessage']),
      placeholderText: _asString(map['placeholderText']),
      launcherWelcomeMessage: _asString(map['launcherWelcomeMessage']),
      connectingStatusText: _asString(map['connectingStatusText']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(raw);

  @override
  String toString() =>
      'WidgetConfig(themeId: $themeId, themeName: $themeName)';
}

/// Theme block of [WidgetConfig].
class WidgetTheme {
  final String? assistantName;
  final String? primaryColor;
  final String? primaryHoverColor;
  final String? headerBackgroundColor;
  final String? headerTextColor;
  final String? backgroundColor;
  final String? backgroundImage;
  final String? surfaceColor;
  final String? textColor;
  final String? textMutedColor;
  final String? borderColor;
  final String? userBubbleColor;
  final String? userBubbleTextColor;
  final String? assistantBubbleColor;
  final String? assistantBubbleTextColor;
  final String? composeBarBackgroundColor;
  final String? composeBarTextColor;
  final String? composeBarPlaceholderColor;
  final int? borderRadius;
  final String? messageBubbleRadius;
  final String? density;
  final int? baseFontSize;
  final String? launcherVariant;
  final String? launcherLabel;
  final String? launcherIcon;
  final String? launcherShape;
  final String? launcherSize;
  final int? launcherRadius;
  final String? launcherBackgroundColor;
  final String? launcherIconColor;
  final bool? launcherWelcomeEnabled;
  final String? launcherWelcomeMessage;
  final int? offset;
  final bool? darkMode;

  /// The original, unmodified `theme` payload.
  final Map<String, dynamic> raw;

  const WidgetTheme({
    this.assistantName,
    this.primaryColor,
    this.primaryHoverColor,
    this.headerBackgroundColor,
    this.headerTextColor,
    this.backgroundColor,
    this.backgroundImage,
    this.surfaceColor,
    this.textColor,
    this.textMutedColor,
    this.borderColor,
    this.userBubbleColor,
    this.userBubbleTextColor,
    this.assistantBubbleColor,
    this.assistantBubbleTextColor,
    this.composeBarBackgroundColor,
    this.composeBarTextColor,
    this.composeBarPlaceholderColor,
    this.borderRadius,
    this.messageBubbleRadius,
    this.density,
    this.baseFontSize,
    this.launcherVariant,
    this.launcherLabel,
    this.launcherIcon,
    this.launcherShape,
    this.launcherSize,
    this.launcherRadius,
    this.launcherBackgroundColor,
    this.launcherIconColor,
    this.launcherWelcomeEnabled,
    this.launcherWelcomeMessage,
    this.offset,
    this.darkMode,
    this.raw = const {},
  });

  factory WidgetTheme.fromMap(Map<String, dynamic> map) {
    return WidgetTheme(
      assistantName: _asString(map['assistantName']),
      primaryColor: _asString(map['primaryColor']),
      primaryHoverColor: _asString(map['primaryHoverColor']),
      headerBackgroundColor: _asString(map['headerBackgroundColor']),
      headerTextColor: _asString(map['headerTextColor']),
      backgroundColor: _asString(map['backgroundColor']),
      backgroundImage: _asString(map['backgroundImage']),
      surfaceColor: _asString(map['surfaceColor']),
      textColor: _asString(map['textColor']),
      textMutedColor: _asString(map['textMutedColor']),
      borderColor: _asString(map['borderColor']),
      userBubbleColor: _asString(map['userBubbleColor']),
      userBubbleTextColor: _asString(map['userBubbleTextColor']),
      assistantBubbleColor: _asString(map['assistantBubbleColor']),
      assistantBubbleTextColor: _asString(map['assistantBubbleTextColor']),
      composeBarBackgroundColor: _asString(map['composeBarBackgroundColor']),
      composeBarTextColor: _asString(map['composeBarTextColor']),
      composeBarPlaceholderColor: _asString(map['composeBarPlaceholderColor']),
      borderRadius: _asInt(map['borderRadius']),
      messageBubbleRadius: _asString(map['messageBubbleRadius']),
      density: _asString(map['density']),
      baseFontSize: _asInt(map['baseFontSize']),
      launcherVariant: _asString(map['launcherVariant']),
      launcherLabel: _asString(map['launcherLabel']),
      launcherIcon: _asString(map['launcherIcon']),
      launcherShape: _asString(map['launcherShape']),
      launcherSize: _asString(map['launcherSize']),
      launcherRadius: _asInt(map['launcherRadius']),
      launcherBackgroundColor: _asString(map['launcherBackgroundColor']),
      launcherIconColor: _asString(map['launcherIconColor']),
      launcherWelcomeEnabled: _asBool(map['launcherWelcomeEnabled']),
      launcherWelcomeMessage: _asString(map['launcherWelcomeMessage']),
      offset: _asInt(map['offset']),
      darkMode: _asBool(map['darkMode']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(raw);

  @override
  String toString() =>
      'WidgetTheme(primaryColor: $primaryColor, darkMode: $darkMode)';
}

String? _asString(dynamic value) => value is String ? value : null;

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) => value is bool ? value : null;
