import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/theme_controller.dart';
import 'package:online_learning_app/routes/app_routes.dart';
import 'admin_widgets.dart';
import '../../../utils/theme_helper.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _doc = FirebaseFirestore.instance.doc('settings/platform');

  bool _loading = true;
  bool _saving = false;
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  final _platformNameCtrl = TextEditingController();
  final _supportEmailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _platformNameCtrl.dispose();
    _supportEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final snap = await _doc.get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        setState(() {
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _allowNewRegistrations = data['allowNewRegistrations'] ?? true;
          _platformNameCtrl.text = data['platformName'] ?? '';
          _supportEmailCtrl.text = data['supportEmail'] ?? '';
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _doc.set({
        'maintenanceMode': _maintenanceMode,
        'allowNewRegistrations': _allowNewRegistrations,
        'platformName': _platformNameCtrl.text.trim(),
        'supportEmail': _supportEmailCtrl.text.trim(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.adminHome);
        }
      },
      child: AdminPageWrapper(
        title: 'Settings',
        showBackButton: true,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  adminHeroHeader(
                    title: 'Settings',
                    subtitle: 'Theme, platform access, and support details',
                  ),
                  const SizedBox(height: 16),
                  adminSectionHeader('Platform'),
                  StaggeredItem(
                    delay: const Duration(milliseconds: 60),
                    child: adminListCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.build_outlined,
                            color: AdminColors.brand,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Maintenance mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'Disables access for regular users',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _maintenanceMode,
                            activeThumbColor: AdminColors.brand,
                            onChanged: (v) =>
                                setState(() => _maintenanceMode = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StaggeredItem(
                    delay: const Duration(milliseconds: 120),
                    child: adminListCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_add_outlined,
                            color: AdminColors.brand,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Allow new registrations',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'Let new users create accounts',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _allowNewRegistrations,
                            activeThumbColor: AdminColors.brand,
                            onChanged: (v) =>
                                setState(() => _allowNewRegistrations = v),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  StaggeredItem(
                    delay: const Duration(milliseconds: 180),
                    child: adminListCard(
                      child: ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeController().mode,
                        builder: (context, mode, _) {
                          final isDark = mode == ThemeMode.dark;
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: AdminColors.brand,
                            ),
                            title: Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              isDark
                                  ? 'Dark theme active'
                                  : 'Light theme active',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            value: isDark,
                            activeThumbColor: AdminColors.brand,
                            onChanged: (_) => ThemeController().toggle(),
                          );
                        },
                      ),
                    ),
                  ),

                  adminSectionHeader('Branding & Contact'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _platformNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Platform name',
                      prefixIcon: Icon(
                        Icons.label_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: context.cardColor,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFD9E2EC)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                          color: AdminColors.brand,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _supportEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Support email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: context.cardColor,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: Color(0xFFD9E2EC)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                          color: AdminColors.brand,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  adminPrimaryButton(
                    onPressed: _saving ? null : _save,
                    isLoading: _saving,
                    child: const Text('Save settings'),
                  ),
                ],
              ),
      ),
    );
  }
}
