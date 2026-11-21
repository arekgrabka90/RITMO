import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import 'entry_form.dart';

void openForm(BuildContext context, {Tip? tip}) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => EntryForm(tip: tip)));
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tips = store.visible;
        final now = DateTime.now();
        final month = tips.where((t) => t.date.year == now.year && t.date.month == now.month);
        final monthNet = month.fold<int>(0, (s, t) => s + t.net);

        return Scaffold(
          appBar: AppBar(title: const Text('Napiwnik')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj napiwki'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              const WorkplaceChips(),
              const SizedBox(height: 12),
              _Hero(monthNet: monthNet, goal: store.goal, month: now),
              const SizedBox(height: 8),
              if (tips.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'Brak wpisów. Po zmianie dotknij „Dodaj napiwki” i wpisz gotówkę oraz kartę.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ..._groups(context, tips),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _groups(BuildContext context, List<Tip> tips) {
    final out = <Widget>[];
    DateTime? last;
    for (final t in tips) {
      if (last == null || last != t.date) {
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Text(
            toBeginningOfSentenceCase(DateFormat('EEEE, d MMMM', 'pl').format(t.date))!,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ));
        last = t.date;
      }
      out.add(_TipTile(tip: t));
    }
    return out;
  }
}

class _Hero extends StatelessWidget {
  final int monthNet;
  final int goal;
  final DateTime month;
  const _Hero({required this.monthNet, required this.goal, required this.month});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final progress = goal > 0 ? (monthNet / goal).clamp(0.0, 1.0) : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Netto w ${DateFormat('LLLL', 'pl').format(month)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            fmtMoney(monthNet),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontFeatures: tabular,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: kBrass,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              monthNet >= goal
                  ? 'Cel ${fmtMoney(goal)} osiągnięty'
                  : 'Do celu ${fmtMoney(goal)}: brakuje ${fmtMoney(goal - monthNet)}',
              style: TextStyle(color: s.onPrimary.withOpacity(0.85), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final Tip tip;
  const _TipTile({required this.tip});

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
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
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
                await store.addTip(tip.asNew());
              } catch (_) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('Nie udało się cofnąć usunięcia.')));
              }
            },
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openForm(context, tip: tip),
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
