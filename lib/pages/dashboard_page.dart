import 'package:flutter/material.dart';

import '../models/qr_record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.state,
    required this.navigate,
  });

  final AppState state;
  final ValueChanged<int> navigate;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final created = state.records
              .where((item) => item.kind == QrRecordKind.created)
              .length;
          final scanned = state.records.length - created;
          return SingleChildScrollView(
            padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (MediaQuery.sizeOf(context).width < 900) ...[
                        const BrandMark(),
                        const Spacer(),
                        IconButton(
                          onPressed: state.toggleTheme,
                          icon: Icon(state.darkMode
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined),
                        ),
                      ] else
                        const Spacer(),
                    ]),
                    if (MediaQuery.sizeOf(context).width < 900)
                      const SizedBox(height: 30),
                    const PageHeading(
                      'Make every scan count.',
                      'Create, capture, and find your QR codes in one calm workspace.',
                    ),
                    const SizedBox(height: 28),
                    LayoutBuilder(builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 700;
                      final hero = _HeroAction(
                        title: 'Create a QR code',
                        subtitle: 'Turn any link or message into a scannable moment.',
                        icon: Icons.add_rounded,
                        color: AppColors.violet,
                        onTap: () => navigate(1),
                      );
                      final scan = _HeroAction(
                        title: 'Scan a code',
                        subtitle: 'Point your camera and capture details instantly.',
                        icon: Icons.center_focus_strong,
                        color: AppColors.coral,
                        onTap: () => navigate(2),
                      );
                      return stacked
                          ? Column(children: [hero, const SizedBox(height: 14), scan])
                          : Row(children: [
                              Expanded(child: hero),
                              const SizedBox(width: 18),
                              Expanded(child: scan),
                            ]);
                    }),
                    const SizedBox(height: 28),
                    Wrap(spacing: 14, runSpacing: 14, children: [
                      _MetricCard(
                        label: 'Created',
                        value: '$created',
                        icon: Icons.auto_awesome_outlined,
                        color: AppColors.violet,
                      ),
                      _MetricCard(
                        label: 'Scanned',
                        value: '$scanned',
                        icon: Icons.qr_code_scanner_rounded,
                        color: AppColors.coral,
                      ),
                      _MetricCard(
                        label: 'Saved locally',
                        value: '${state.records.length}',
                        icon: Icons.lock_outline_rounded,
                        color: AppColors.mint,
                      ),
                    ]),
                    const SizedBox(height: 30),
                    Row(children: [
                      Text('Recent activity',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              )),
                      const Spacer(),
                      if (state.records.isNotEmpty)
                        TextButton(
                            onPressed: () => navigate(3), child: const Text('View all')),
                    ]),
                    const SizedBox(height: 12),
                    if (state.records.isEmpty)
                      SectionCard(
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(children: [
                            Icon(Icons.inbox_outlined,
                                size: 42,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 12),
                            const Text('Your activity will appear here.'),
                            const SizedBox(height: 4),
                            Text('Create or scan your first QR code to get started.',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ]),
                        ),
                      )
                    else
                      SectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: state.records.take(4).map((record) {
                            final last = record == state.records.take(4).last;
                            return Column(children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: (record.kind == QrRecordKind.created
                                          ? AppColors.violet
                                          : AppColors.coral)
                                      .withValues(alpha: .12),
                                  child: Icon(
                                    record.kind == QrRecordKind.created
                                        ? Icons.add_rounded
                                        : Icons.center_focus_strong,
                                    color: record.kind == QrRecordKind.created
                                        ? AppColors.violet
                                        : AppColors.coral,
                                  ),
                                ),
                                title: Text(record.title,
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(record.value,
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Text(_relativeTime(record.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall),
                              ),
                              if (!last) const Divider(height: 1, indent: 76),
                            ]);
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  static String _relativeTime(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ]),
          ),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 205,
        child: SectionCard(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      )),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ]),
        ),
      );
}

