import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/providers/database_provider.dart';

/// Plain-text CV editor. Kept deliberately simple — a single text field
/// persisted to Users.resumeText — rather than a structured multi-section
/// builder, since there's no CV template/rendering requirement yet.
class CvEditorScreen extends ConsumerStatefulWidget {
  const CvEditorScreen({super.key});

  @override
  ConsumerState<CvEditorScreen> createState() => _CvEditorScreenState();
}

class _CvEditorScreenState extends ConsumerState<CvEditorScreen> {
  final _controller = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(userDaoProvider).updateResumeText(
          _controller.text.trim().isEmpty ? null : _controller.text.trim(),
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.literal('CV saved'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    userAsync.whenData((user) {
      if (!_loaded) {
        _loaded = true;
        _controller.text = user?.resumeText ?? '';
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(S.literal('Your CV')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(S.literal('Save')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.literal('Write your experience, skills, and education. This is shown to employers alongside your job applications.'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: S.literal('e.g. Experience, skills, education...'),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.skillsColor, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
