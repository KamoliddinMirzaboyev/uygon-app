import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';

import 'theme.dart';

/// A rounded "inset grouped" block of rows separated by hairlines.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(const Divider(indent: 16));
      }
      rows.add(children[i]);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// One row: title on the left, value + chevron on the right.
class GroupRow extends StatelessWidget {
  const GroupRow({
    super.key,
    required this.title,
    this.value,
    this.onTap,
    this.trailing,
    this.chevron = true,
    this.titleColor,
  });

  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool chevron;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(title, style: TextStyle(fontSize: 17, color: titleColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child:
                      trailing ??
                      (value == null
                          ? const SizedBox.shrink()
                          : Text(
                              value!,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 17, color: muted),
                            )),
                ),
              ),
              if (chevron && onTap != null)
                Icon(Icons.chevron_right, color: muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class IosSwitch extends StatelessWidget {
  const IosSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => CupertinoSwitch(
    value: value,
    onChanged: onChanged,
    activeTrackColor: const Color(0xFF34C759),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 20, 16, 6),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    ),
  );
}

const kOrangeText = TextStyle(color: kAccent, fontSize: 17);
