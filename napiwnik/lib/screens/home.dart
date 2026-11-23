import 'package:flutter/material.dart';

import '../models.dart';
import '../percent.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import 'entry_form.dart';

/// Formularz wpisu napiwków. Z [shift] otwiera się z danymi zmiany z grafiku.
void openForm(BuildContext context, {Tip? tip, Shift? shift}) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => EntryForm(tip: tip, shift: shift)),
  );
}

class WorkplaceChips extends StatelessWidget {
  const WorkplaceChips({super.key});

  @override
  Widget build(BuildContext context) {
    if (store.workplaces.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Wszystkie'),
              selected: store.filterId == null,
              onSelected: (_) => store.setFilter(null),
            ),
          ),
          for (final w in store.workplaces)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(w.name),
                selected: store.filterId == w.id,
                onSelected: (_) => store.setFilter(w.id),
              ),
            ),
        ],
      ),
    );
  }
}

Shift? _linkedShiftOf(Tip tip) {
  for (final sh in store.shifts) {
    if (sh.tipId == tip.id) return sh;
  }
  return null;
}

/// Usuwa wpis napiwków i pokazuje „Cofnij”. Zmiana z grafiku połączona z wpisem po cofnięciu
/// usunięcia znowu się z nim łączy. Wołaj synchronicznie z obsługi gestu.
Future<void> deleteTipWithUndo(BuildContext context, Tip tip) async {
  final messenger = ScaffoldMessenger.of(context);
  final linkedShift = _linkedShiftOf(tip);
  final ok = await store.deleteTip(tip);
  messenger.clearSnackBars();
  if (!ok) {
    messenger.showSnackBar(const SnackBar(content: Text('Nie udało się usunąć wpisu.')));
    return;
  }
  messenger.showSnackBar(SnackBar(
    content: const Text('Usunięto wpis'),
    action: SnackBarAction(
      label: 'Cofnij',
      onPressed: () async {
        try {
          if (linkedShift == null) {
            await store.addTip(tip.asNew());
          } else {
            await store.addTipForShift(tip.asNew(), linkedShift);
          }
        } catch (_) {
          messenger.showSnackBar(
              const SnackBar(content: Text('Nie udało się cofnąć usunięcia.')));
        }
      },
    ),
  ));
}

/// Przytrzymanie wpisu: lista opcji.
void showTipOptions(BuildContext context, Tip tip) {
  final error = Theme.of(context).colorScheme.error;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Netto ${fmtMoney(tip.net)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edytuj wpis'),
            onTap: () {
              Navigator.pop(ctx);
              openForm(context, tip: tip);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: error),
            title: Text('Usuń wpis', style: TextStyle(color: error)),
            onTap: () {
              Navigator.pop(ctx);
              deleteTipWithUndo(context, tip);
            },
          ),
        ],
      ),
    ),
  );
}

/// Wiersz wpisu napiwków: dotknięcie edytuje, przytrzymanie daje opcje, przesunięcie usuwa.
class TipTile extends StatelessWidget {
  final Tip tip;
  const TipTile({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final parts = <String>[
      if (tip.cash > 0) 'gotówka ${fmtMoney(tip.cash)}',
      if (tip.card > 0) 'karta ${fmtMoney(tip.card)}',
      if (tip.tipOut > 0) 'odliczono ${fmtMoney(tip.tipOut)}',
    ];
    if (parts.isEmpty) parts.add('bez napiwków');
    final ph = tip.perHour;
    final hoursText = tip.hours == null
        ? null
        : '${fmtHours(tip.hours!)} h'
            '${ph != null ? ' · ${fmtMoney(ph.round())}/h' : ''}';
    final pct = tip.tipPercent;
    final salesText = tip.sales == null
        ? null
        : 'utarg ${fmtMoney(tip.sales!)}${pct != null ? ' · ${fmtPercent(pct)}' : ''}';

    return Dismissible(
      key: ValueKey('tip-${tip.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: s.errorContainer, borderRadius: BorderRadius.circular(14)),
        child: Icon(Icons.delete_outline, color: s.onErrorContainer),
      ),
      onDismissed: (_) => deleteTipWithUndo(context, tip),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openForm(context, tip: tip),
          onLongPress: () => showTipOptions(context, tip),
          child: Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.workplaceName(tip.workplaceId),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(parts.join(' · '), style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                      if (hoursText != null)
                        Text(hoursText, style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                      if (salesText != null)
                        Text(salesText, style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                      if (tip.note.isNotEmpty)
                        Text(tip.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: s.onSurfaceVariant, fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(fmtMoney(tip.net),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFeatures: tabular)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
