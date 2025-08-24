import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/language/locale_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/profile/about_us.dart';
import 'package:matajer/screens/profile/manage_notifications.dart';
import 'package:matajer/screens/profile/privacy_policy.dart';
import 'package:matajer/screens/profile/support.dart';

class AppSettings extends StatelessWidget {
  const AppSettings({super.key});

  final int _selectedLangIndex = 0; // 0 = EN, 1 = AR (replace with your logic)

  @override
  Widget build(BuildContext context) {
    final List<_AppSettingItem> settings = [
      _AppSettingItem(
        title: S.of(context).manage_notifications,
        subtitle: S.of(context).notifications_tip,
        widget: const ManageNotifications(),
      ),
      _AppSettingItem(
        title: S.of(context).app_language,
        subtitle: S.of(context).choose_language,
        isLanguageSelector: true,
      ),
      _AppSettingItem(
        title: S.of(context).privacy_policy,
        subtitle: S.of(context).privacy_tip,
        widget: const PrivacyPolicyPage(),
      ),
      _AppSettingItem(
        title: S.of(context).matajer_support,
        subtitle: S.of(context).support_tip,
        widget: const MatajerSupport(),
      ),
      _AppSettingItem(
        title: S.of(context).about_matajer,
        subtitle: S.of(context).about_tip,
        widget: const AboutUs(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).app_settings,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: greyColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              itemCount: settings.length,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Divider(thickness: 2, color: greyColor.withOpacity(0.2)),
              ),
              itemBuilder: (context, index) {
                final setting = settings[index];

                return ListTile(
                  contentPadding: EdgeInsets.fromLTRB(
                    15,
                    setting.subtitle.isEmpty
                        ? 0
                        : index == 0
                        ? 12
                        : 8,
                    10,
                    setting.subtitle.isEmpty
                        ? 0
                        : index == settings.length - 1
                        ? 12
                        : 8,
                  ),
                  onTap: setting.isLanguageSelector || setting.widget == null
                      ? null
                      : () {
                          slideAnimation(
                            context: context,
                            destination: setting.widget!,
                            rightSlide: true,
                          );
                        },
                  title: Text(
                    setting.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: setting.subtitle.isEmpty
                      ? null
                      : Text(
                          setting.subtitle,
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  trailing: setting.isLanguageSelector
                      ? _buildLanguageSelector()
                      : Icon(forwardIcon(), color: Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return SizedBox(
          width: lang == 'en' ? 130.w : 170.w,
          child: Row(
            children: [
              Expanded(
                child: _buildLangChip(
                  S.of(context).english,
                  isSelected: lang == 'en',
                  onTap: () {
                    context.read<LocaleCubit>().changeLocale('en'); // or 'ar'
                  },
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildLangChip(
                  S.of(context).arabic,
                  isSelected: lang == 'ar',
                  onTap: () {
                    context.read<LocaleCubit>().changeLocale('ar'); // or 'ar'
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangChip(
    String lang, {
    required bool isSelected,
    required void Function()? onTap,
  }) {
    return Material(
      color: isSelected ? primaryColor : primaryColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Text(
              lang,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppSettingItem {
  final String title;
  final String subtitle;
  final Widget? widget;
  final bool isLanguageSelector;

  const _AppSettingItem({
    required this.title,
    required this.subtitle,
    this.widget,
    this.isLanguageSelector = false,
  });
}
