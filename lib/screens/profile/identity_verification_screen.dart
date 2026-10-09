import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_colors.dart';
import '../../services/identity_verification_service.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final _service = IdentityVerificationService();
  VerificationStatus _status = VerificationStatus.none;
  String _documentType = 'Government ID';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final status = await _service.getStatus(uid);
    if (mounted) setState(() => _status = status);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final file = await _service.pickIdDocument();
      if (file == null) return;
      await _service.submitVerification(documentType: _documentType, idImage: file);
      if (mounted) {
        setState(() => _status = VerificationStatus.pending);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID submitted for review. Documents are stored privately.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Status: ${_status.label}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload a government ID or student ID. Files are encrypted in transit '
            'and stored in a private Firebase Storage path accessible only to you '
            'and platform administrators.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _documentType,
            decoration: const InputDecoration(labelText: 'Document type'),
            items: const [
              DropdownMenuItem(value: 'Government ID', child: Text('Government ID')),
              DropdownMenuItem(value: 'Student ID', child: Text('Student ID')),
            ],
            onChanged: _busy ? null : (v) => setState(() => _documentType = v!),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy || _status == VerificationStatus.approved ? null : _submit,
            child: Text(_busy ? 'Uploading…' : 'Upload ID Document'),
          ),
        ],
      ),
    );
  }
}
