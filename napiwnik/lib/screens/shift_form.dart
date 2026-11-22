import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dates.dart';
import '../models.dart';
import '../planning.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

void openShiftForm(BuildContext context, {Shift? shift, DateTime? date}) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ShiftForm(shift: shift, initialDate: date)),
  );
}

/// Pojedyncza zmiana: dodawanie i edycja.
class ShiftForm extends StatefulWidget {
  final Shift? shift;
  final DateTime? initialDate;
  const ShiftForm({super.key, this.shift, this.initialDate});

  @override
  State<ShiftForm> createState() => _ShiftFormState();
}

class _ShiftFormState extends State<ShiftForm> {
  late DateTime _date;
  int? _wid;
  late TimeRange _range;
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    if (s != null) {
      _date = s.date;
      _wid = s.workplaceId;
      _range = TimeRange(s.startMin, s.endMin);
      _note.text = s.note;
    } else {
      _date = dateOnly(widget.initialDate ?? DateTime.now());
      _wid = store.filterId ??
          (store.workplaces.length == 1 ? store.workplaces.first.id : null);
      _range = store.lastRange;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = dateOnly(DateTime.now());
    final first = DateTime(2015);
    final last = DateTime(now.year + 2, 12, 31);
    var initial = _date;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (d != null) setState(() => _date = dateOnly(d));
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    if (_saving) return;
    if (!_range.valid) {
      _toast('Początek i koniec zmiany nie mogą być takie same.');
      return;
    }
    final shift = Shift(
      id: widget.shift?.id,
      workplaceId: _wid,
      date: _date,
      startMin: _range.start,
      endMin: _range.end,
      note: _note.text.trim(),
      tipId: widget.shift?.tipId,
    );
    setState(() => _saving = true);
    try {
      if (widget.shift == null) {
        await store.addShift(shift);
      } else {
        await store.updateShift(shift);
      }
      await store.setLastRange(_range);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Nie udało się zapisać zmiany. Spróbuj ponownie.');
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.shift?.isDone == true;
    return Scaffold(
      appBar: AppBar(title: Text(widget.shift == null ? 'Nowa zmiana' : 'Edytuj zmianę')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
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
          TimeRangeField(range: _range, onChanged: (r) => setState(() => _range = r)),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notatka'),
          ),
          if (done) ...[
            const SizedBox(height: 16),
            const Panel(
              child: Text(
                'Napiwki do tej zmiany są już wpisane. Zmiana godzin tutaj nie zmienia tamtego wpisu.',
              ),
            ),
          ],
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
