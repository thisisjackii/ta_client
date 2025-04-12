import 'package:flutter/material.dart';

class StatExpandableCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Map<String, String>> valuesAboveDivider;
  final List<Map<String, String>> valuesBelowDivider;

  const StatExpandableCard({
    super.key,
    required this.title,
    required this.icon,
    required this.valuesAboveDivider,
    required this.valuesBelowDivider,
  });

  @override
  State<StatExpandableCard> createState() => _StatExpandableCardState();
}

class _StatExpandableCardState extends State<StatExpandableCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => isExpanded = !isExpanded);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),

              // Expanded Content
              if (isExpanded) ...[
                const SizedBox(height: 16),
                ...widget.valuesAboveDivider.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry['label']!, style: const TextStyle(fontSize: 14)),
                      Text(entry['value']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
                const Divider(),
                const SizedBox(height: 8),
                ...widget.valuesBelowDivider.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry['label']!, style: const TextStyle(fontSize: 14)),
                      Text(entry['value']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
