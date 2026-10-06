import 'package:flutter/material.dart';

import '../../domain/entry_tag.dart';
import '../../l10n/app_localizations.dart';

/// The icon of [tag], used on chips and in the timeline.
IconData tagIcon(EntryTag tag) => switch (tag) {
  EntryTag.food => Icons.restaurant_outlined,
  EntryTag.view => Icons.landscape_outlined,
  EntryTag.stay => Icons.hotel_outlined,
  EntryTag.beach => Icons.beach_access_outlined,
  EntryTag.sight => Icons.account_balance_outlined,
  EntryTag.transport => Icons.directions_bus_outlined,
};

/// The localized name of [tag].
String tagLabel(AppLocalizations l10n, EntryTag tag) => switch (tag) {
  EntryTag.food => l10n.tagFood,
  EntryTag.view => l10n.tagView,
  EntryTag.stay => l10n.tagStay,
  EntryTag.beach => l10n.tagBeach,
  EntryTag.sight => l10n.tagSight,
  EntryTag.transport => l10n.tagTransport,
};

/// One chip per tag; a tap sets or clears it.
class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.selected, required this.onChanged});

  final Set<EntryTag> selected;
  final ValueChanged<Set<EntryTag>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in EntryTag.values)
          FilterChip(
            avatar: Icon(tagIcon(tag), size: 18),
            showCheckmark: false,
            label: Text(tagLabel(l10n, tag)),
            selected: selected.contains(tag),
            onSelected: (isSelected) => onChanged(
              isSelected ? {...selected, tag} : ({...selected}..remove(tag)),
            ),
          ),
      ],
    );
  }
}

/// The tags of an entry as small icons, e.g. in the timeline.
class TagIcons extends StatelessWidget {
  const TagIcons({super.key, required this.tags});

  final Set<EntryTag> tags;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tag in tags)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              tagIcon(tag),
              size: 18,
              color: color,
              semanticLabel: tagLabel(l10n, tag),
            ),
          ),
      ],
    );
  }
}
