import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/generated/l10n.dart';

class CustomExpandableRichText extends StatefulWidget {
  final String text;
  final Color linkColor, textColor;
  final double? textWidth, textHeight, fontSize;
  final int maxLines;
  final FontWeight fontWeight;

  const CustomExpandableRichText({
    super.key,
    required this.text,
    this.textWidth,
    this.fontWeight = FontWeight.w700,
    this.textHeight = 1.4,
    this.fontSize = 15,
    this.linkColor = primaryColor,
    this.textColor = Colors.black,
    this.maxLines = 3,
  });

  @override
  State<CustomExpandableRichText> createState() =>
      _CustomExpandableRichTextState();
}

class _CustomExpandableRichTextState extends State<CustomExpandableRichText> {
  bool expanded = false;

  TextStyle _baseStyle() => TextStyle(
    height: widget.textHeight,
    color: widget.textColor,
    fontSize: widget.fontSize,
    fontWeight: widget.fontWeight,
  );

  TextStyle _boldStyle() => TextStyle(
    height: widget.textHeight,
    color: widget.textColor,
    fontSize: widget.fontSize! + 2,
    fontWeight: FontWeight.w900,
  );

  TextSpan parseStyledText(String input) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*(.*?)\*');
    final matches = regex.allMatches(input);

    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: input.substring(currentIndex, match.start),
            style: _baseStyle(),
          ),
        );
      }
      spans.add(TextSpan(text: match.group(1), style: _boldStyle()));
      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      spans.add(
        TextSpan(text: input.substring(currentIndex), style: _baseStyle()),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final originalTextSpan = parseStyledText(widget.text);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: originalTextSpan,
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final exceeded = tp.didExceedMaxLines;

        if (!exceeded) {
          return GestureDetector(
            onTap: _toggleExpand,
            child: RichText(text: originalTextSpan),
          );
        }

        final seeMoreSpan = TextSpan(
          text: expanded
              ? " ${S.of(context).see_less}"
              : " ${S.of(context).see_more}",
          style: TextStyle(
            color: widget.linkColor,
            fontWeight: FontWeight.bold,
          ),
        );

        TextSpan displaySpan;
        if (expanded) {
          displaySpan = TextSpan(children: [originalTextSpan, seeMoreSpan]);
        } else {
          final truncatedText = _truncateTextToFit(
            originalTextSpan,
            constraints.maxWidth,
            widget.maxLines,
            seeMoreSpan,
          );
          displaySpan = truncatedText;
        }

        return GestureDetector(
          onTap: _toggleExpand,
          child: RichText(
            maxLines: expanded ? null : widget.maxLines,
            overflow: expanded ? TextOverflow.visible : TextOverflow.clip,
            text: displaySpan,
          ),
        );
      },
    );
  }

  void _toggleExpand() {
    setState(() {
      expanded = !expanded;
    });
  }

  TextSpan _truncateTextToFit(
    TextSpan fullText,
    double maxWidth,
    int maxLines,
    TextSpan linkSpan,
  ) {
    final styledChars = <MapEntry<String, TextStyle?>>[];
    void extractChars(TextSpan span) {
      if (span.text != null) {
        for (var rune in span.text!.runes) {
          styledChars.add(MapEntry(String.fromCharCode(rune), span.style));
        }
      }
      if (span.children != null) {
        for (var child in span.children!) {
          if (child is TextSpan) extractChars(child);
        }
      }
    }

    extractChars(fullText);

    int low = 0, high = styledChars.length;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      final testSpan = TextSpan(
        children: [
          _charsToSpan(styledChars.sublist(0, mid)),
          TextSpan(text: '...', style: _baseStyle()),
          linkSpan,
        ],
      );

      final tp = TextPainter(
        text: testSpan,
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (tp.didExceedMaxLines) {
        high = mid - 1;
      } else {
        low = mid;
      }
    }

    return TextSpan(
      children: [
        _charsToSpan(styledChars.sublist(0, low)),
        TextSpan(text: '...', style: _baseStyle()),
        linkSpan,
      ],
    );
  }

  TextSpan _charsToSpan(List<MapEntry<String, TextStyle?>> chars) {
    if (chars.isEmpty) return const TextSpan();
    final spans = <TextSpan>[];
    String buffer = '';
    TextStyle? currentStyle = chars.first.value;

    for (final entry in chars) {
      if (entry.value == currentStyle) {
        buffer += entry.key;
      } else {
        spans.add(TextSpan(text: buffer, style: currentStyle));
        buffer = entry.key;
        currentStyle = entry.value;
      }
    }
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer, style: currentStyle));
    }
    return TextSpan(children: spans);
  }
}
