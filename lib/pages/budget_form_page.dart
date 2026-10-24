import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/budget_repository.dart';
import '../logic/validators.dart';
import '../models/budget.dart';

/// Form buat / ubah anggaran (nama perjalanan + total anggaran).
class BudgetFormPage extends StatefulWidget {
  const BudgetFormPage({super.key, required this.userId, this.budget});

  final int userId;
  final Budget? budget;

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = BudgetRepository();
  late final TextEditingController _name;
  late final TextEditingController _total;
  bool _saving = false;

  bool get _isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.budget?.name ?? '');
    _total = TextEditingController(
      text: widget.budget == null ? '' : '${widget.budget!.totalAmount}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final total = Validators.parseAmount(_total.text);
      if (_isEdit) {
        await _repo.updateBudget(
          widget.budget!.copyWith(name: name, totalAmount: total),
        );
      } else {
        await _repo.createBudget(
          Budget(
            userId: widget.userId,
            name: name,
            totalAmount: total,
            createdAt: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan anggaran.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ubah Anggaran' : 'Buat Anggaran')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nama perjalanan',
                hintText: 'mis. Studi MSc di Edinburgh',
              ),
              validator: (v) => Validators.name(v, label: 'Nama perjalanan'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _total,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Total anggaran',
                prefixText: 'Rp ',
              ),
              validator: Validators.amount,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
