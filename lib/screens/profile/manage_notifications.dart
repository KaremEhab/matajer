import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/cubit/notifications/notification_state.dart';
import 'package:matajer/generated/l10n.dart';

class ManageNotifications extends StatefulWidget {
  const ManageNotifications({super.key});

  @override
  State<ManageNotifications> createState() => _ManageNotificationsState();
}

class _ManageNotificationsState extends State<ManageNotifications> {
  List<bool> toggledNotifications = [false, true, true, false, true];
  bool isLoading = true;

  final List<_NotificationSettingItem> notifications = [
    _NotificationSettingItem(
      field: 'newProductsNotification',
      title: S.current.new_products,
      subtitle: S.current.new_products_tip,
    ),
    _NotificationSettingItem(
      field: 'commentsNotification',
      title: S.current.comments,
      subtitle: S.current.comments_tip,
    ),
    _NotificationSettingItem(
      field: 'reviewsNotification',
      title: S.current.reviews,
      subtitle: S.current.reviews_tip,
    ),
    _NotificationSettingItem(
      field: 'ordersNotification',
      title: S.current.orders,
      subtitle: S.current.orders_tip,
    ),
    _NotificationSettingItem(
      field: 'messagesNotification',
      title: S.current.messages,
      subtitle: S.current.messages_tip,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};

    setState(() {
      toggledNotifications = notifications.map<bool>((item) {
        return data[item.field] as bool? ?? false;
      }).toList();
      isLoading = false;
    });
  }

  Future<void> _updateNotificationSetting(int index, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final fieldName = notifications[index].field;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      fieldName: value,
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            leadingWidth: 53,
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
            title: Text(
              S.of(context).manage_notifications,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 15,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: greyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Divider(
                        thickness: 2,
                        color: greyColor.withOpacity(0.2),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final item = notifications[index];

                      return SwitchListTile(
                        value: toggledNotifications[index],
                        onChanged: (value) async {
                          setState(() {
                            toggledNotifications[index] = value;
                          });
                          await _updateNotificationSetting(index, value);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                        ),
                        activeColor: primaryColor,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: greyColor.withOpacity(0.3),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: item.subtitle.isEmpty
                            ? null
                            : Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _NotificationSettingItem {
  final String field;
  final String title;
  final String subtitle;

  const _NotificationSettingItem({
    required this.field,
    required this.title,
    required this.subtitle,
  });
}
