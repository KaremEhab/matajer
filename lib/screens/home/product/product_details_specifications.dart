import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';

class ProductDetailsSpecifications extends StatefulWidget {
  const ProductDetailsSpecifications({
    super.key,
    required this.productModel,
    required this.onSpecChanged,
    required this.initialSelectedIndexes,
  });

  final void Function(int specIndex, int selectedIndex, num price)
  onSpecChanged;
  final List<int> initialSelectedIndexes;
  final ProductModel productModel;

  @override
  State<ProductDetailsSpecifications> createState() =>
      _ProductDetailsSpecificationsState();
}

class _ProductDetailsSpecificationsState
    extends State<ProductDetailsSpecifications>
    with AutomaticKeepAliveClientMixin {
  late final List<ValueNotifier<int>> selectedIndexes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // ProductCubit.get(
    //   context,
    // ).increaseProductClicks(productId: widget.productModel.id);

    selectedIndexes = List.generate(
      widget.productModel.specifications.length,
      (i) => ValueNotifier<int>(widget.initialSelectedIndexes[i]),
    );

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   for (int i = 0; i < selectedIndexes.length; i++) {
    //     final price = widget.productModel.specifications[i].subTitles[0].price;
    //     widget.onSpecChanged(i, 0, price);
    //   }
    // });
  }

  @override
  void dispose() {
    for (final notifier in selectedIndexes) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: List.generate(widget.productModel.specifications.length, (
        index,
      ) {
        final spec = widget.productModel.specifications[index];
        final isColorSpec = _isColorSpecification(spec.title);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Text(
                  '${S.of(context).choose_a} ${spec.title}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<int>(
                valueListenable: selectedIndexes[index],
                builder: (_, selected, __) => isColorSpec
                    ? _buildColorOptions(index, spec, selected)
                    : _buildSubtitleOptions(index, spec, selected),
              ),
              if (index != widget.productModel.specifications.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Divider(
                    color: primaryColor.withOpacity(0.1),
                    thickness: 7,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  bool _isColorSpecification(String title) {
    final t = title.toLowerCase();
    return t == 'color' || t == 'colors' || t == 'colour' || t == 'colours';
  }

  Widget _buildColorOptions(int index, spec, int selectedIndex) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: spec.subTitles.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, colorIndex) {
          final subtitle = spec.subTitles[colorIndex].title.trim();
          final color = colorNames[subtitle.toLowerCase().replaceAll(' ', '')];
          final isSelected = selectedIndex == colorIndex;

          if (color == null) return const SizedBox.shrink();

          return GestureDetector(
            onTap: widget.productModel.sellerId == uId
                ? null
                : () => _selectSpec(index, colorIndex, spec),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 15 : 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(isSelected ? 0.1 : 0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  _buildColorDot(color),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                    if (spec.subTitles[colorIndex].price > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          "(+AED ${formatNumberWithCommas(spec.subTitles[colorIndex].price)})",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      height: 25,
      width: 25,
      decoration: ShapeDecoration(
        color: color,
        shape: const CircleBorder(),
        shadows: [
          BoxShadow(
            color: color.computeLuminance() > 0.5
                ? Colors.black12
                : Colors.white24,
            blurRadius: 1,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleOptions(int index, spec, int selectedIndex) {
    return Column(
      children: List.generate(spec.subTitles.length, (subIndex) {
        final subtitle = spec.subTitles[subIndex].title.trim();
        final price = spec.subTitles[subIndex].price.abs();
        final isSelected = selectedIndex == subIndex;

        return ListTile(
          onTap: widget.productModel.sellerId == uId
              ? null
              : () => _selectSpec(index, subIndex, spec),
          contentPadding: EdgeInsets.zero,
          title: Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w400,
              color: isSelected ? primaryColor : textColor,
            ),
          ),
          trailing: widget.productModel.sellerId != uId
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "+AED ${formatNumberWithCommas(price.toDouble())}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected ? primaryColor : textColor,
                      ),
                    ),
                    Radio<int>(
                      activeColor: primaryColor,
                      value: subIndex,
                      groupValue: selectedIndex,
                      onChanged: (_) => _selectSpec(index, subIndex, spec),
                    ),
                  ],
                )
              : null,
        );
      }),
    );
  }

  void _selectSpec(int index, int selectedIndex, spec) {
    selectedIndexes[index].value = selectedIndex;
    widget.onSpecChanged(
      index,
      selectedIndex,
      spec.subTitles[selectedIndex].price,
    );
  }
}
