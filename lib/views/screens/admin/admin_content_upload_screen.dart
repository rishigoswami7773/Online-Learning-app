import 'package:flutter/material.dart';
import 'admin_widgets.dart';

class AdminContentUploadScreen extends StatefulWidget {
  const AdminContentUploadScreen({super.key});
  @override
  State<AdminContentUploadScreen> createState() => _AdminContentUploadScreenState();
}

class _AdminContentUploadScreenState extends State<AdminContentUploadScreen> {
  final _form = GlobalKey<FormState>();
  String _title = '';
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final body = Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(decoration: const InputDecoration(labelText: 'Title'), onSaved: (v) => _title = v ?? ''),
        const SizedBox(height: 12),
        TextFormField(decoration: const InputDecoration(labelText: 'Description'), maxLines: 4),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () {
          _form.currentState?.save();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploading "$_title"...')));
        }, icon: const Icon(Icons.upload_file), label: const Text('Upload')),
      ]),
    );

    // Wrap with AdminPageWrapper for consistent admin header/back behaviour
    return Scaffold(
      body: AdminPageWrapper(
        title: 'Upload Content',
        child: isWide ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: body)) : body,
      ),
    );
  }
}
