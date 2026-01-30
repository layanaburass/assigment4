import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Skin-ish palette
  static const Color skin = Color(0xFFE7C1A2);
  static const Color skinDark = Color(0xFFB07A5B);
  static const Color cream = Color(0xFFFFFBF7);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: skin),
        appBarTheme: const AppBarTheme(
          backgroundColor: skin,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 15)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: skinDark, width: 2),
          ),
          labelStyle: const TextStyle(color: skinDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: skinDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
        ),
      ),
      home: const UsersHome(),
    );
  }
}

class UsersHome extends StatefulWidget {
  const UsersHome({super.key});

  @override
  State<UsersHome> createState() => _UsersHomeState();
}

class _UsersHomeState extends State<UsersHome> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();

  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child(
    'users',
  );

  bool _saving = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validEmail(String s) => s.contains('@') && s.contains('.');

  Future<void> _save() async {
    final name = _nameC.text.trim();
    final email = _emailC.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _snack('Please enter name and email');
      return;
    }
    if (!_validEmail(email)) {
      _snack('Please enter a valid email');
      return;
    }

    setState(() => _saving = true);
    try {
      await _usersRef.push().set({'name': name, 'email': email});
      _nameC.clear();
      _emailC.clear();
      _snack('Saved ');
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEditDialog({
    required String id,
    required String currentName,
    required String currentEmail,
  }) async {
    final nameC = TextEditingController(text: currentName);
    final emailC = TextEditingController(text: currentEmail);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit user'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final newName = nameC.text.trim();
    final newEmail = emailC.text.trim();

    if (newName.isEmpty || newEmail.isEmpty) {
      _snack('Name and email cannot be empty');
      return;
    }
    if (!_validEmail(newEmail)) {
      _snack('Please enter a valid email');
      return;
    }

    try {
      await _usersRef.child(id).update({'name': newName, 'email': newEmail});
      _snack('Updated ');
    } catch (e) {
      _snack('Update failed: $e');
    } finally {
      nameC.dispose();
      emailC.dispose();
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Different layout: top "panel" card + list below, with rounded container.
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts (Firebase)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add new contact',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameC,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving...' : 'Save'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tip: tap any item below to edit it.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEBD6C8)),
                ),
                child: StreamBuilder<DatabaseEvent>(
                  stream: _usersRef.onValue,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const Center(child: Text('Error loading data'));
                    }
                    if (!snap.hasData || snap.data!.snapshot.value == null) {
                      return const Center(child: Text('No data yet'));
                    }

                    final raw =
                        snap.data!.snapshot.value as Map<dynamic, dynamic>;
                    final items = raw.entries.toList().reversed.toList();

                    return ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final entry = items[i];
                        final id = entry.key.toString();
                        final user = entry.value as Map<dynamic, dynamic>;

                        final name = (user['name'] ?? '').toString();
                        final email = (user['email'] ?? '').toString();

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openEditDialog(
                            id: id,
                            currentName: name,
                            currentEmail: email,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEBD6C8),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFE7C1A2),
                                  child: Text(
                                    name.isEmpty ? '?' : name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _openEditDialog(
                                    id: id,
                                    currentName: name,
                                    currentEmail: email,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
