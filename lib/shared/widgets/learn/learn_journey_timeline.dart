import 'package:flutter/material.dart';
import 'learn_ui.dart';

enum LearnJourneyStatus { completed, current, next }

class LearnJourneyItem {
  const LearnJourneyItem({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final LearnJourneyStatus status;
}

class LearnJourneyTimeline extends StatelessWidget {
  const LearnJourneyTimeline({super.key, required this.items});

  final List<LearnJourneyItem> items;

  @override
  Widget build(BuildContext context) {
    final ui = LearnUi.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(LearnUi.radiusCard),
        border: Border.all(color: ui.border),
        boxShadow: ui.softShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _JourneyRow(
              item: items[i],
              isLast: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({required this.item, required this.isLast});

  final LearnJourneyItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ui = LearnUi.of(context);
    final isDone = item.status == LearnJourneyStatus.completed;
    final isCurrent = item.status == LearnJourneyStatus.current;

    final Color dotColor;
    if (isDone) {
      dotColor = LearnUi.success;
    } else if (isCurrent) {
      dotColor = LearnUi.accent;
    } else {
      dotColor = ui.border;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDone || isCurrent ? dotColor : ui.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone || isCurrent ? dotColor : ui.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: ui.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCurrent
                                ? ui.textPrimary
                                : ui.textPrimary.withValues(
                                    alpha: isDone ? 0.85 : 0.55,
                                  ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _statusLabel(item.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? LearnUi.success
                              : isCurrent
                                  ? LearnUi.accent
                                  : ui.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: ui.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(LearnJourneyStatus status) {
    switch (status) {
      case LearnJourneyStatus.completed:
        return 'Completed';
      case LearnJourneyStatus.current:
        return 'Current';
      case LearnJourneyStatus.next:
        return 'Next';
    }
  }
}
