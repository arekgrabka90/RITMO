import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import 'shared.dart';
import 'shift_form.dart';

/// Usuwa zmianę i pokazuje „Cofnij”. Wołaj synchronicznie z obsługi gestu (messenger jest brany od razu).
Future<void> deleteShiftWithUndo(BuildContext context, Shift shift) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await store.deleteShift(shift);
  messenger.clearSnackBars();
  if (!ok) {
    messenger.showSnackBar(const SnackBar(content: Text('Nie udało się usunąć zmiany.')));
    return;
  }
  messenger.showSnackBar(SnackBar(
    content: const Text('Usunięto zmianę'),
    action: SnackBarAction(
      label: 'Cofnij',
      onPressed: () async {
        try {
          await store.addShift(shift.asNew());
        } catch (_) {
          messenger.showSnackBar(
              const SnackBar(content: Text('Nie udało się cofnąć usunięcia.')));
        }
      },
    ),
  ));
}

/// Dotknięcie zmiany: zakończona bez napiwków otwiera wpis napiwków, zakończona z napiwkami
/// otwiera ten wpis, a pozostałe (jeszcze się nie odbyły) otwierają edycję zmiany.
void openShiftDefault(BuildContext context, Shift s) {
  if (s.hasEnded(DateTime.now())) {
    if (!s.isDone) {
      openForm(context, shift: s);
      return;
    }
    final tip = store.tipById(s.tipId!);
    if (tip != null) {
      openForm(context, tip: tip);
      return;
    }
  }
  openShiftForm(context, shift: s);
}

/// Przytrzymanie zmiany: lista opcji.
void showShiftOptions(BuildContext context, Shift shift) {
  final tip = shift.tipId == null ? null : store.tipById(shift.tipId!);
  final ended = shift.hasEnded(DateTime.now());
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
                '${fmtTimeRange(shift.startMin, shift.endMin)} · ${fmtDuration(shift.durationMin)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edytuj zmianę'),
            onTap: () {
              Navigator.pop(ctx);
              openShiftForm(context, shift: shift);
            },
          ),
          if (ended && !shift.isDone)
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Wpisz napiwki'),
              onTap: () {
                Navigator.pop(ctx);
                openForm(context, shift: shift);
              },
            ),
          if (shift.isDone && tip != null)
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Edytuj napiwki'),
              onTap: () {
                Navigator.pop(ctx);
                openForm(context, tip: tip);
              },
            ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: error),
            title: Text('Usuń zmianę', style: TextStyle(color: error)),
            onTap: () {
              Navigator.pop(ctx);
              deleteShiftWithUndo(context, shift);
            },
          ),
        ],
      ),
    ),
  );
}

/// Przesunięcie w lewo usuwa zmianę (z możliwością cofnięcia).
class ShiftDismissible extends StatelessWidget {
  final Shift shift;
  final Widget child;
  final EdgeInsets backgroundMargin;
  final double radius;

  const ShiftDismissible({
    super.key,
    required this.shift,
    required this.child,
    this.backgroundMargin = EdgeInsets.zero,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('shift-${shift.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: backgroundMargin,
        decoration: BoxDecoration(
          color: s.errorContainer,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(Icons.delete_outline, color: s.onErrorContainer),
      ),
      onDismissed: (_) => deleteShiftWithUndo(context, shift),
      child: child,
    );
  }
}
