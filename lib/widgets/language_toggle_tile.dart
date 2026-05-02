import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/language_service.dart';

/// Language switch (Hindi / English). Rebuild when [LanguageService.localeNotifier] changes.
class LanguageToggleTile extends StatelessWidget {
  const LanguageToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.localeNotifier,
      builder: (ctx, locale, _) {
        final isHindi = locale.languageCode == 'hi';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withValues(alpha: 0.1),
              child: const Icon(Icons.language, color: Colors.indigo, size: 20),
            ),
            title: Text(
              AppStrings.t(ctx, 'language'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              isHindi ? AppStrings.t(ctx, 'use_english') : AppStrings.t(ctx, 'use_hindi'),
            ),
            trailing: Switch(
              value: isHindi,
              onChanged: (value) async {
                await LanguageService.setLanguage(value ? 'hi' : 'en');
              },
            ),
          ),
        );
      },
    );
  }
}
