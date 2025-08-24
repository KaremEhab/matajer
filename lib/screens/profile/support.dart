import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';

class MatajerSupport extends StatefulWidget {
  const MatajerSupport({super.key});

  @override
  State<MatajerSupport> createState() => _MatajerSupportState();
}

class _MatajerSupportState extends State<MatajerSupport> {
  late Map<String, List<String>> supportSections;
  late Map<String, List<bool>> expandedSubtitles;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    supportSections = {
      S.of(context).payment_issues: [
        S.of(context).why_payment_declined,
        S.of(context).refund_issues,
        S.of(context).charging_twice_issues,
        S.of(context).update_payment_method_issues,
        S.of(context).multi_payment_issues,
      ],
      S.of(context).order_issues: [
        S.of(context).receiving_wrong_order_issues,
        S.of(context).cancel_order_issues,
        S.of(context).delayed_order_issues,
      ],
    };

    expandedSubtitles = {
      for (var key in supportSections.keys)
        key: List.generate(supportSections[key]!.length, (_) => false),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filteredSections = supportSections.map((header, subtitles) {
      final filtered =
          subtitles
              .where(
                (subtitle) =>
                    subtitle.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();
      return MapEntry(header, filtered);
    });

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leadingWidth: 52,
        leading: Padding(
          padding: EdgeInsets.fromLTRB(
            lang == 'en' ? 7 : 0,
            6,
            lang == 'en' ? 0 : 7,
            6,
          ),
          child: Material(
            color: lightGreyColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () {
                Navigator.pop(context);
              },
              child: Center(
                child: Icon(backIcon(), color: textColor, size: 26),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          S.of(context).matajer_support,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 7),
        child: Column(
          children: [
            // 🔍 Search Field
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: S.of(context).searching_for_topic,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: lightGreyColor.withOpacity(0.2),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 5),

            // 📋 List
            Expanded(
              child: ListView(
                children:
                    filteredSections.entries.map((entry) {
                      final header = entry.key;
                      final filteredSubtitles = entry.value;

                      if (filteredSubtitles.isEmpty) return const SizedBox();

                      final originalSubtitles = supportSections[header]!;
                      final expansionStates = expandedSubtitles[header]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              header,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),

                          // Filtered Subtitles
                          ...filteredSubtitles.map((subtitle) {
                            final index = originalSubtitles.indexOf(subtitle);
                            final isExpanded = expansionStates[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                children: [
                                  Material(
                                    color: lightGreyColor.withOpacity(0.4),
                                    borderRadius:
                                        isExpanded
                                            ? const BorderRadius.only(
                                              topLeft: Radius.circular(15),
                                              topRight: Radius.circular(15),
                                            )
                                            : BorderRadius.circular(15),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(15),
                                      onTap: () {
                                        setState(() {
                                          expansionStates[index] =
                                              !expansionStates[index];
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                subtitle,
                                                style: TextStyle(
                                                  fontSize: 17.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: primaryColor,
                                              size: 26,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isExpanded)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: lightGreyColor.withOpacity(0.15),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        "This is the detail or explanation for \"$subtitle\".",
                                        style: TextStyle(
                                          fontSize: 14.5.sp,
                                          color: textColor.withOpacity(0.85),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
