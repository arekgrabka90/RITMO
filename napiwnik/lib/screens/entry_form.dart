import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dates.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

class EntryForm extends StatefulWidget {
  final Tip? tip;

  /// Zmiana z grafiku, z której wpisujemy napiwki (tylko dla nowego wpisu).
  final Shift? shift;
  const EntryForm({super.key, this.tip, this.shift});

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  late DateTime _date;
  int? _wid;
  bool _saving = false;
  final _cash = TextEditingController();
  final _card = TextEditingController();
  final _out = TextEditingController();
  final _hours = TextEditingController();
  final _note = TextEditingController();

  Shift? get _linked => widget.tip == null ? widget.shift : null;

  @override
  void initState() {
    super.initState();
    final t = widget.tip;
    final linked = _linked;
    if (t != null) {
      _date = t.date;
      _wid = t.workplaceId;
      _cash.text = fmtInput(t.cash);
      _card.text = fmtInput(t.card);
      _out.text = fmtInput(t.tipOut);
      _hours.text = t.hours == null ? '' : fmtHours(t.hours!);
      _note.text = t.note;
    } else if (linked != null) {
      _date = linked.date;
      _wid = linked.workplaceId;
      _hours.text = fmtHours(linked.hours);
    } else {
      _date = dateOnly(DateTime.now());
      _wid = store.filterId ??
          (store.workplaces.length == 1 ? store.workplaces.first.id : null);
    }
  }

  @override
  void dispose() {
    for (final c in [_cash, _card, _out, _hours, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Napiwki można wpisać najpóźniej dla dzisiejszego dnia (zmiana, która się jeszcze nie odbyła,
  /// nie ma napiwków).
  Future<void> _pickDate() async {
    final last = dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(last) ? last : _date,
      firstDate: DateTime(2015),
      lastDate: last,
    );
    if (d != null) setState(() => _date = dateOnly(d));
  }

  Future<void> _save() async {
    if (_saving) return;
    final linked = _linked;
    if (linked != null && !linked.hasEnded(DateTime.now())) {
      _toast('Ta zmiana jeszcze się nie zakończyła. Napiwki wpiszesz po jej końcu.');
      return;
    }
    final cash = parseMoney(_cash.text);
    final card = parseMoney(_card.text);
    final out = parseMoney(_out.text);
    final hours = parseHours(_hours.text);
    final hoursOk = _hours.text.trim().isEmpty || hours != null;
    if (cash == null || card == null || out == null || !hoursOk) {
      _toast('Sprawdź kwoty i godziny (np. 120,50 oraz 6,5). Kwota może mieć najwyżej 2 miejsca po przecinku.');
      return;
    }
    // Przyszła data tylko dla starego wpisu, którego daty nie ruszamy (wcześniej było to dozwolone).
    final dateChanged = widget.tip == null || widget.tip!.date != _date;
    if (_date.isAfter(dateOnly(DateTime.now())) && dateChanged) {
      _toast('Napiwki można wpisać najwcześniej dla dzisiejszego dnia.');
      return;
    }
    // Zmiana bez napiwków jest dozwolona, ale wymaga godzin (inaczej to pusty wpis).
    if (cash + card == 0 && hours == null) {
      _toast('Wpisz kwotę napiwków albo godziny (zmiana bez napiwków: same godziny).');
      return;
    }
    if (out > cash + card) {
      _toast('Odliczenie nie może być większe niż suma napiwków.');
      return;
    }
    final tip = Tip(
      id: widget.tip?.id,
      workplaceId: _wid,
      date: _date,
      cash: cash,
      card: card,
      tipOut: out,
      hours: hours,
      note: _note.text.trim(),
    );
    setState(() => _saving = true);
    try {
      if (linked != null) {
        await store.addTipForShift(tip, linked);
      } else if (widget.tip == null) {
        await store.addTip(tip);
      } else {
        await store.updateTip(tip);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Nie udało się zapisać wpisu. Spróbuj ponownie.');
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final linked = _linked;
    final cash = parseMoney(_cash.text) ?? 0;
    final card = parseMoney(_card.text) ?? 0;
    final out = parseMoney(_out.text) ?? 0;
    final net = cash + card - out;
    final hours = parseHours(_hours.text);
    final money = const TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(linked != null
            ? 'Napiwki ze zmiany'
            : (widget.tip == null ? 'Nowy wpis' : 'Edytuj wpis')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (linked != null) ...[
            Panel(
              child: Row(children: [
                const Icon(Icons.event_note),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Zmiana z grafiku: ${fmtTimeRange(linked.startMin, linked.endMin)} · ${fmtDuration(linked.durationMin)}',
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: linked != null ? null : _pickDate,
            icon: const Icon(Icons.event),
            label: Text(DateFormat('EEEE, d MMMM y', 'pl').format(_date)),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 16),
          if (store.workplaces.isNotEmpty) ...[
            DropdownButtonFormField<int?>(
              value: _wid,
              decoration: const InputDecoration(labelText: 'Miejsce pracy'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Bez miejsca')),
                for (final w in store.workplaces)
                  DropdownMenuItem<int?>(value: w.id, child: Text(w.name)),
              ],
              onChanged: (v) => setState(() => _wid = v),
            ),
            const SizedBox(height: 16),
          ],
          Row(children: [
            Expanded(
              child: TextField(
                controller: _cash,
                keyboardType: money,
                decoration: const InputDecoration(labelText: 'Gotówka', suffixText: 'zł'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _card,
                keyboardType: money,
                decoration: const InputDecoration(labelText: 'Karta', suffixText: 'zł'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _out,
            keyboardType: money,
            decoration: const InputDecoration(
              labelText: 'Odliczenie (np. podział z barem lub kuchnią)',
              suffixText: 'zł',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hours,
            keyboardType: money,
            decoration: const InputDecoration(labelText: 'Przepracowane godziny', suffixText: 'h'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notatka'),
          ),
          const SizedBox(height: 20),
          Panel(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Netto'),
                    if (hours != null && net >= 0)
                      Text('${fmtMoney((net / hours).round())} na godzinę',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
                Text(fmtMoney(net),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontFeatures: tabular)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}
