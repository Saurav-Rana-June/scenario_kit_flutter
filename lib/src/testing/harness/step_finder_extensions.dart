import 'package:flutter_test/flutter_test.dart';

import '../definitions/step_finder.dart';

/// Extension on [StepFinder] that converts declarative finding strategies into
/// official Flutter test [Finder] instances.
extension StepFinderWidgetTesterExtension on StepFinder {
  /// Converts this [StepFinder] into a `flutter_test` [Finder].
  Finder toWidgetTesterFinder() {
    switch (type) {
      case StepFinderType.byKey:
        return find.byKey(key!);

      case StepFinderType.byText:
        return find.textContaining(text!, findRichText: findRichText);

      case StepFinderType.byType:
        return find.byType(widgetType!);

      case StepFinderType.byTooltip:
        return find.byTooltip(tooltip!);

      case StepFinderType.byIcon:
        return find.byIcon(icon!);

      case StepFinderType.custom:
        return find.byElementPredicate(
          (element) => matchesElement(element),
          description: description,
        );

      case StepFinderType.bySemanticsLabel:
        return find.bySemanticsLabel(semanticsLabel!);
    }
  }
}
