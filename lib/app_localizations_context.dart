import 'package:flutter/widgets.dart';
import 'package:running_app/l10n/app_localizations.dart';

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l1on => AppLocalizations.of(this)!;
}
