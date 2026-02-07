import 'package:flutter/material.dart';
import '../constants/companies.dart';

class CreateCourierDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required String username,
    required String password,
    required List<String> companies,
  })
  onSubmit;

  const CreateCourierDialog({super.key, required this.onSubmit});

  @override
  State<CreateCourierDialog> createState() => _CreateCourierDialogState();
}

class _CreateCourierDialogState extends State<CreateCourierDialog> {
  final _nameC = TextEditingController();
  final _userC = TextEditingController();
  final _passC = TextEditingController();
  final _selected = <String>{};
  bool _loading = false;

  @override
  void dispose() {
    _nameC.dispose();
    _userC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text("Novo Entregador"),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameC,
                decoration: const InputDecoration(
                  labelText: "Nome completo",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userC,
                decoration: const InputDecoration(
                  labelText: "Nome de usuário",
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passC,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Empresas que ele atende",
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCourierCompanies.entries.map((e) {
                  return FilterChip(
                    label: Text(e.value),
                    selected: _selected.contains(e.key),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(e.key);
                        } else {
                          _selected.remove(e.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              if (_selected.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Selecione pelo menos 1 empresa.",
                      style: TextStyle(color: cs.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  final name = _nameC.text.trim();
                  final username = _userC.text.trim();
                  final password = _passC.text.trim();
                  if (name.isEmpty || username.isEmpty || password.isEmpty)
                    return;
                  if (_selected.isEmpty) return;

                  setState(() => _loading = true);
                  try {
                    await widget.onSubmit(
                      name: name,
                      username: username,
                      password: password,
                      companies: _selected.toList(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Cadastrar"),
        ),
      ],
    );
  }
}
