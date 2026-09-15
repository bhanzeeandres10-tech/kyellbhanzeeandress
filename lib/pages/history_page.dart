import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/qr_record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

enum HistoryFilter { all, created, scanned }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.state});
  final AppState state;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String query = '';
  HistoryFilter filter = HistoryFilter.all;

  List<QrRecord> get filtered => widget.state.records.where((record) {
        final matchesQuery = query.isEmpty ||
            record.title.toLowerCase().contains(query.toLowerCase()) ||
            record.value.toLowerCase().contains(query.toLowerCase());
        final matchesFilter = filter == HistoryFilter.all ||
            (filter == HistoryFilter.created && record.kind == QrRecordKind.created) ||
            (filter == HistoryFilter.scanned && record.kind == QrRecordKind.scanned);
        return matchesQuery && matchesFilter;
      }).toList();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                PageHeading(
                  'History',
                  '${widget.state.records.length} items stored privately on this device.',
                  action: widget.state.records.isEmpty
                      ? null
                      : TextButton.icon(
                          onPressed: _confirmClear,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: const Text('Clear all'),
                        ),
                ),
                const SizedBox(height: 24),
                SectionCard(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final search = TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Search your QR history',
                      ),
                    );
                    final filters = SegmentedButton<HistoryFilter>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: HistoryFilter.all, label: Text('All')),
                        ButtonSegment(value: HistoryFilter.created, label: Text('Created')),
                        ButtonSegment(value: HistoryFilter.scanned, label: Text('Scanned')),
                      ],
                      selected: {filter},
                      onSelectionChanged: (value) => setState(() => filter = value.first),
                    );
                    return constraints.maxWidth < 660
                        ? Column(children: [search, const SizedBox(height: 12), filters])
                        : Row(children: [
                            Expanded(child: search),
                            const SizedBox(width: 14),
                            filters,
                          ]);
                  }),
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  SectionCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(children: [
                        Icon(query.isEmpty ? Icons.history_toggle_off : Icons.search_off_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(query.isEmpty ? 'No history yet' : 'No matching codes',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text(query.isEmpty
                            ? 'Created and scanned QR codes will be saved here.'
                            : 'Try another search or filter.'),
                      ]),
                    ),
                  )
                else
                  SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: filtered.map((record) => _HistoryTile(
                            record: record,
                            onDelete: () => widget.state.removeRecord(record.id),
                          )).toList(),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This removes every saved QR item from this browser.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (confirmed == true) await widget.state.clearHistory();
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.onDelete});
  final QrRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final created = record.kind == QrRecordKind.created;
    final accent = created ? AppColors.violet : AppColors.coral;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(created ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
                color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(record.type,
                      style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(record.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(_formatDate(record.createdAt), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          IconButton(
            tooltip: 'Copy',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: record.value));
              if (context.mounted) showAppSnackBar(context, 'Content copied.');
            },
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ]),
      ),
      const Divider(height: 1),
    ]);
  }

  String _formatDate(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day}/${date.year} Â· $hour:$minute $period Â· ${record.kind.name}';
  }
}

