import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:matajer/constants/bloc_observer.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/theme_data.dart';
import 'package:matajer/constants/vars.dart';

import 'package:matajer/cubit/comments/comments_cubit.dart';
import 'package:matajer/cubit/analytics/analytics_cubit.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/cubit/wallet/wallet_cubit.dart';
import 'package:matajer/cubit/register/register_cubit.dart';
import 'package:matajer/cubit/login/login_cubit.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/filter/filter_cubit.dart';
import 'package:matajer/cubit/reviews/reviews_cubit.dart';
import 'package:matajer/new_chat/chat_cubit.dart';

import 'package:matajer/firebase_options.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/google_auth/access_firebase_token.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:matajer/screens/home/shop/shop_comments.dart';
import 'package:matajer/screens/orders/order_details_screen.dart';
import 'package:matajer/screens/profile/order_details.dart';
import 'package:matajer/screens/reviews/reviews.dart';
import 'package:matajer/screens/splash/matajer_splash.dart';
import 'package:matajer/screens/whatsApp/chat_page.dart';

import 'cubit/language/locale_cubit.dart';

// ───────────────────────────────────────────────

bool get isIOSSimulator {
  return Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
}

// ───────────────────────────────────────────────
// 🔔 Global Keys
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// ───────────────────────────────────────────────
// 🔔 Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupFlutterNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.actionId == 'reply') {
        final replyText = response.input?.trim();
        if (replyText?.isEmpty ?? true) return;

        final payload = response.payload;
        if (payload != null) {
          final data = jsonDecode(payload);
          await ChatsCubit.instance.sendNewTextMessage(
            text: replyText!,
            chatId: data['chatId'],
            receiverId: data['senderId'],
            receiverName: data['receiverName'],
            receiverImage: data['receiverImage'],
          );
        }
      } else {
        handleNotificationTap(response.payload);
      }
    },
  );

  // 👇 Listen to FCM messages
  FirebaseMessaging.onMessage.listen(showLocalNotification);
}

Future<void> showLocalNotification(RemoteMessage message) async {
  final data = message.data;
  final type = data['type'];

  final notificationDetails = type == 'chat'
      ? const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'reply',
                'Reply',
                inputs: [
                  AndroidNotificationActionInput(label: 'Type message...'),
                ],
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(),
        )
      : const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        );

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title,
    message.notification?.body,
    notificationDetails,
    payload: jsonEncode(data),
  );
}

void handleNotificationTap(String? payload) {
  if (payload == null) return;
  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final NotificationTypes type = NotificationTypes.values.byName(
      data['type'],
    );
    final navigator = navigatorKey.currentState!;
    final shouldReplace = navigator.canPop();

    switch (type) {
      case NotificationTypes.chat:
        navigator.pushReplacementIfNeeded(
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              chatId: data['chatId'],
              isFromNotification: true,
              senderId: data['receiverId'],
              receiverId: data['senderId'],
              receiverName: data['receiverName'],
              receiverImage: data['receiverImage'],
            ),
          ),
          shouldReplace,
        );
        break;

      case NotificationTypes.newOrder:
        // Adjusted: using safe access for map entry
        final orderMap = jsonDecodeIfNeeded(data['orderModel']);
        final order = OrderModel.fromJson(
          Map<String, dynamic>.from(orderMap),
          orderMap['id'],
        );
        navigator.pushReplacementIfNeeded(
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
          shouldReplace,
        );
        break;

      case NotificationTypes.review:
        final product = ProductModel.fromJson(
          Map<String, dynamic>.from(jsonDecodeIfNeeded(data['productModel'])),
        );
        navigator.pushReplacementIfNeeded(
          MaterialPageRoute(builder: (_) => Reviews(productModel: product)),
          shouldReplace,
        );
        break;

      case NotificationTypes.comment:
        final shop = ShopModel.fromJson(
          Map<String, dynamic>.from(jsonDecodeIfNeeded(data['shopModel'])),
        );
        navigator.pushReplacementIfNeeded(
          MaterialPageRoute(builder: (_) => ShopComments(shopModel: shop)),
          shouldReplace,
        );
        break;

      case NotificationTypes.newProduct:
        final product = ProductModel.fromJson(
          Map<String, dynamic>.from(jsonDecodeIfNeeded(data['productModel'])),
        );
        final shop = ShopModel.fromJson(
          Map<String, dynamic>.from(jsonDecodeIfNeeded(data['shopModel'])),
        );
        navigator.pushReplacementIfNeeded(
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailsScreen(productModel: product, shopModel: shop),
          ),
          shouldReplace,
        );
        break;

      case NotificationTypes.orderStatus:
        // Adjusted: using safe access for map entry
        final orderMap = jsonDecodeIfNeeded(data['orderModel']);
        final order = OrderModel.fromJson(
          Map<String, dynamic>.from(orderMap),
          orderMap['id'],
        );
        navigator.pushReplacementIfNeeded(
          MaterialPageRoute(builder: (_) => OrderDetails(order: order)),
          shouldReplace,
        );
        break;

      default:
        break;
    }
  } catch (e) {
    log("❌ Notification tap error: $e");
  }
}

dynamic jsonDecodeIfNeeded(dynamic input) =>
    input is String ? jsonDecode(input) : input;

extension on NavigatorState {
  void pushReplacementIfNeeded(MaterialPageRoute route, bool shouldReplace) {
    if (shouldReplace) {
      pushReplacement(route);
    } else {
      push(route);
    }
  }
}

// ───────────────────────────────────────────────
// 🌐 Internet Check
Future<bool> hasInternetConnection() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}

late final bool isInitialInternetAvailable;

// 🚀 Entry Point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!isIOSSimulator) {
    await setupFlutterNotifications();
  } else {
    log("⚠️ Skipping local notifications setup on iOS Simulator");
  }

  Bloc.observer = MyBlocObserver();
  await CacheHelper.init();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  isInitialInternetAvailable = await hasInternetConnection();

  // Cache
  uId = await CacheHelper.getData(key: 'uId') ?? '';
  lang = await CacheHelper.getData(key: 'lang') ?? 'en';
  shopStatus = await CacheHelper.getData(key: 'shopStatus') ?? true;
  isGuest = await CacheHelper.getData(key: 'isGuest') ?? false;
  autoAcceptOrders =
      await CacheHelper.getData(key: 'autoAcceptOrders') ?? false;
  skipOnboarding = await CacheHelper.getData(key: 'skipOnboarding') ?? false;

  String? finalFcmToken;

  if (isInitialInternetAvailable) {
    try {
      // 👇 Request iOS notification permission
      if (Platform.isIOS && !isIOSSimulator) {
        final settings = await FirebaseMessaging.instance.requestPermission();
        log("🔔 iOS permission: ${settings.authorizationStatus}");

        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );

        // Add a small delay to allow APNS to register before fetching the token
        await Future.delayed(const Duration(milliseconds: 500));

        // Fetch APNs token (optional, but good for debugging)
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        log("📲 APNs token: $apnsToken");

        // 🚨 Fetch the FCM token after a small delay
        finalFcmToken = await FirebaseMessaging.instance.getToken();
      } else if (isIOSSimulator) {
        log("⚠️ Running on iOS Simulator → Skipping APNs and FCM token setup");
      } else {
        // Android case
        finalFcmToken = await FirebaseMessaging.instance.getToken();
      }

      if (finalFcmToken != null) {
        log("🔑 Fetched FCM Token: $finalFcmToken");
      }
    } catch (e) {
      // This catch block handles the APNS token error gracefully
      log("⚠️ Token fetch failed: $e");
    }
  }

  runApp(
    MyApp(
      // Pass the potentially null token
      initialFcmToken: finalFcmToken,
    ),
  );
}

// ───────────────────────────────────────────────
// 🧱 App Widget
class MyApp extends StatelessWidget {
  final String? initialFcmToken;

  const MyApp({super.key, this.initialFcmToken});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LocaleCubit()),
        BlocProvider(create: (_) => RegisterCubit()),
        BlocProvider(create: (_) => LoginCubit()),
        BlocProvider(create: (_) => UserCubit()),
        BlocProvider(create: (_) => ProductCubit()),
        BlocProvider(create: (_) => OrderCubit()),
        BlocProvider(create: (_) => AnalyticsCubit()),
        BlocProvider(create: (_) => ChatCubit()),
        BlocProvider(create: (_) => ChatsCubit()),
        BlocProvider(create: (_) => WalletCubit()),
        BlocProvider(create: (_) => FavoritesCubit()),
        BlocProvider(create: (_) => NotificationCubit()),
        BlocProvider(create: (_) => FilterCubit()),
        BlocProvider(create: (_) => ReviewsCubit()),
        BlocProvider(create: (_) => CommentsCubit()),
      ],
      child: Builder(
        // 🚨 Added Builder to access context before ScreenUtilInit
        builder: (context) {
          // 🚨 CRITICAL FIX: Update FCM token here using the UserCubit
          if (initialFcmToken != null && uId.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // This relies on the updateUserFCMToken method being implemented in UserCubit
              UserCubit.get(
                context,
              ).updateUserFCMToken(token: initialFcmToken!);
            });
          }

          // 🚨 Optional: Listen for token refresh and update the user's profile
          // IMPORTANT: Only listen if not running on simulator
          if (!isIOSSimulator) {
            FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
              if (uId.isNotEmpty) {
                UserCubit.get(context).updateUserFCMToken(token: newToken);
                log("🔄 FCM Token Refreshed: $newToken");
              }
            });
          }

          return ScreenUtilInit(
            designSize: const Size(430, 932),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, __) {
              return BlocBuilder<LocaleCubit, Locale>(
                builder: (context, locale) {
                  return MaterialApp(
                    navigatorKey: navigatorKey,
                    debugShowCheckedModeBanner: false,
                    scaffoldMessengerKey: scaffoldMessengerKey,
                    locale: locale,
                    supportedLocales: S.delegate.supportedLocales,
                    localizationsDelegates: const [
                      S.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    theme: Styles.themeData(context: context),
                    home: const MatajerSplash(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
