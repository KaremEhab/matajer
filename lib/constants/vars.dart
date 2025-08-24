import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/cubit/analytics/analytics_cubit.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/cubit/wallet/wallet_cubit.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/cubit/register/register_cubit.dart';
import 'package:matajer/cubit/login/login_cubit.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/new_chat/chat_cubit.dart';

List<BlocProvider> providers = [
  BlocProvider(create: (context) => RegisterCubit()),
  BlocProvider(create: (context) => LoginCubit()),
  BlocProvider(create: (context) => UserCubit()),
  BlocProvider(create: (context) => ProductCubit()),
  BlocProvider(create: (context) => OrderCubit()),
  BlocProvider(create: (context) => AnalyticsCubit()),
  BlocProvider(create: (context) => ChatCubit()),
  BlocProvider(create: (context) => ChatsCubit()),
  BlocProvider(create: (context) => NotificationCubit()),
  BlocProvider(create: (context) => WalletCubit()),
  BlocProvider(create: (context) => FavoritesCubit()),
];

IconData backIcon() {
  return lang == 'en' ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right;
}

IconData forwardIcon() {
  return lang == 'en' ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left;
}

late String uId;
late String lang;
bool skipOnboarding = false;
bool isGuest = false;
late GuestUserModel guestUserModel;
bool shopStatus = true;
bool userRegistered = false;
bool autoAcceptOrders = false;
String? fcmDeviceToken;
late String accessToken;
String? cartShopId;
String? chatReceiverName;
String? chatReceiverImage;

double bannerHeight = 0.2.sh;
double bannerWidth = 0.94.sw;

bool isSeller = false;
double scrollOffset = 0;

double homeCategoriesOffset = 0.4.sh;

// Set the max and min font sizes
const double maxTitleFontSize = 37;
const double minTitleFontSize = 0;

const double maxSubtitleFontSize = 17;
const double minSubtitleFontSize = 0;

double titleFontSize = 0;
double subtitleFontSize = 0;

bool isInChatPage = false;

late UserModel currentUserModel;
ShopModel? currentShopModel;

const String shopSearchHistoryKey = 'shopSearchHistory';
const String productSearchHistoryKey = 'productSearchHistory';

enum NotificationTypes { chat, offer, newProduct, comment, review, newOrder, orderStatus}

List<String> categoriesText = [
  'Matajir',
  'Cheap',
  'Gifts',
  'Events',
  'Shops',
  'Food',
  'Drinks',
];

List<String> subCategoriesText = [
  "All",
  "Football",
  "Soccer Cleats",
  "Running",
  "Casual",
  "Wedding",
];

List<String> categoriesImages = [
  'images/shop.png',
  'images/wallet.png',
  'images/gift.png',
  'images/event.png',
  'images/shop.png',
  'images/vegetables.png',
  'images/drink.png',
  'images/vegetables.png',
  'images/drink.png',
  'images/event.png',
  'images/gift.png',
  'images/shop.png',
];

// Predefined color name map
final colorNames = {
  'red': Colors.red,
  'blue': Colors.blue,
  'green': Colors.green,
  'yellow': Colors.yellow,
  'orange': Colors.orange,
  'purple': Colors.purple,
  'pink': Colors.pink,
  'black': Colors.black,
  'white': Colors.white,
  'grey': Colors.grey,
  'brown': Colors.brown,
  'cyan': Colors.cyan,
  'indigo': Colors.indigo,
  'teal': Colors.teal,
  'lime': Colors.lime,
  'amber': Colors.amber,
  'deeporange': Colors.deepOrange,
  'deeppurple': Colors.deepPurple,
  'lightblue': Colors.lightBlue,
  'lightgreen': Colors.lightGreen,
  'bluegrey': Colors.blueGrey,
  'beige': Color(0xFFF5F5DC),
  'babyblue': Color(0xFFADD8E6),
  'mintgreen': Color(0xFF98FF98),
  'offwhite': Color(0xFFFAF9F6),
};

final List<String> matajerSortOptions = [
  'A -> Z',
  'Top Rated',
  'Recommended',
  // 'Distance',
  'Newest',
  'Oldest',
  // 'Most Viewed',
];

final List<String> productsSortOptions = [
  'A -> Z',
  'Top Rated',
  'Recommended',
  'Price: Low -> High',
  'Price: High -> Low',
  // 'Distance',
  'Newest',
  'Oldest',
  'Most Viewed',
];

final List<String> cities = [
  'Abu Dhabi',
  'Dubai',
  'Sharjah',
  'Ajman',
  'Umm Al-Quwain',
  'Ras Al Khaimah',
  'Fujairah',
  'Gharbya (Western Region)',
  'Al-Ain',
];

final Map<String, IconData> categoryEnglishIcons = {
  "Fashion": Icons.checkroom,
  "Food": Icons.fastfood,
  "Electronics": Icons.devices,
  "Furniture": Icons.chair,
  "Beauty": Icons.brush,
  "Gifts": Icons.card_giftcard,
  "Kids": Icons.child_friendly,
  "Sports": Icons.fitness_center,
  "Stationery": Icons.menu_book,
  "Tools": Icons.handyman,
  "Hardware": Icons.build,
  "Services": Icons.miscellaneous_services,
};

List<Map<String, dynamic>> matajerEnglishCategories = [
  {
    "name": "Fashion",
    "subCategories": ["Men", "Women", "Children", "Footwear", "Accessories"],
  },
  {
    "name": "Food",
    "subCategories": [
      "Pizza",
      "Burger",
      "Sandwiches",
      "Fried Chicken",
      "Grilled Food",
      "Seafood",
      "Pasta",
      "Asian Food",
      "Indian Food",
      "Shawarma & Kebab",
      "Salads",
      "Soups",
      "Vegan & Vegetarian",
      "Sweets & Desserts",
      "Beverages",
      "Groceries",
      "Snacks",
      "Breakfast",
      "Wraps & Rolls",
      "BBQ & Smoked",
    ],
  },
  {
    "name": "Electronics",
    "subCategories": [
      "Mobile Phones",
      "Computers",
      "Laptops",
      "Home Appliances",
      "Gaming",
      "Audio",
    ],
  },
  {"name": "Furniture", "subCategories": []},
  {
    "name": "Beauty",
    "subCategories": [
      "Makeup",
      "Skincare",
      "Haircare",
      "Fragrances",
      "Personal Hygiene",
    ],
  },
  {
    "name": "Gifts",
    "subCategories": ["Customized", "Handmade", "Parties", "Birthday"],
  },
  {
    "name": "Kids",
    "subCategories": ["Toys", "Baby Care", "School Supplies"],
  },
  {
    "name": "Sports",
    "subCategories": ["Equipment", "Activewear", "Nutrition"],
  },
  {
    "name": "Stationery",
    "subCategories": ["Books", "Supplies"],
  },
  {
    "name": "Tools",
    "subCategories": ["Hand Tools", "Building Materials"],
  },
  {
    "name": "Hardware",
    "subCategories": ["Power Tools", "Paint & Coatings"],
  },
  {
    "name": "Services",
    "subCategories": [
      "Tailoring",
      "Shoe Repair",
      "Key Cutting",
      "Electronics Repair",
      "Cleaning Services",
    ],
  },
];


// import 'package:googleapis_auth/auth_io.dart';
//
// class AccessTokenFirebase {
//   static String firebaseMessagingScope =
//       'https://www.googleapis.com/auth/firebase.messaging';
//
//   Future<String> getAccessToken() async {
//     final client = await clientViaServiceAccount(
//       ServiceAccountCredentials.fromJson(
//         {
//           "type": "service_account",
//           "project_id": "matajr-40a00",
//           "private_key_id": "09736ca50b019b7cb99c92e5fc5250c20e85487d",
//           "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC70QHmJNypEA+G\ntgAc4yJe19Yr08ySpkh8w6JEoSk8W+qnJyKKmEKHwsSlxvyuK4ahbRf++YyywEFB\nwhABYUahdEE7aLOQy7jskN6i+bzS6ZTS+wNZMJm/m45GO3+G3CXmm0h4Y7RprmFO\nNlUo8keFqwkrjhfHdLyEqSkb9P2VG4feHJwFCtGXHBgnDiGZfKHin2f4DlraFIio\ngKjDZHyGq/bjunWu4vwdrMeZ0gLXgHNX9sTcOtOK5Y65ePp35P5pSK0plXF85HaO\nzlycHg+6EWHKemu0JQIlYK9yKon35M/G9+7QixRo1Bbg/qmX/4PCLoZ02IX8DOll\n7OxqFTJrAgMBAAECggEANA2XxKS3wWVxoCjF/DuZNYcFVS1Et+o9EdMYoIO4DYH+\nFWibwqSzX7QD01xEgLMQg6HcMi8QpyPwkhyKWg+PR0UUpTX9+mXz8SCvi6TCiAPz\n2st14Jy/J+MheeaYkBRorrKf0bn0cQvC7S3SyV/ooavHBVrCzWVVsEC/438xXscB\nRtDsG8IKDP7fMbnlO5icR2JvQeqwZVCSWZor/P5RpJvilYW0jFHVmQRREC5gXqkj\n14WcOGLpZhFk+6q1sEzym/x9Oy08zdqgBlal4CBEYeth5PosBcO8W/7IPvd8ga+T\nWOaLA9SR7GY2F9FpmKfvheHHUC6/hoJ6z9WmPFIVwQKBgQD85bkpxphPP367F7vv\neUWQGBz+MhMCFe2y2s4W8pteLcxVDQ6cxn98UEff5l55I7BPmbCXbxZDzlkZ7htQ\n48IaZE636HKO3ZhqeY24VvzJgjaCBinjgNcqA6AaHyiXcBmNyIZaz7bONisdis8T\niP/Cq02EAMqWx+AFMjd7xoJzQQKBgQC+HuJLjYVOdDaCJ4bPXi62oT0U8UXdjDDu\nbHJ+/1sG3gOXP4HEoDiRyBT0YPV1H9Sy9Y1gwBtBWhbo7gOEmGeoVqahSv7f9Qh3\nm7HURWG0r5apKS3EyQQdola2GMf8QMWrQbzrfNthk4jeE/w/zuQgibFujnAax4mF\nYPrYjIK2qwKBgBFZcSp8hVZqdLdBGZOELlGEVfjaVpN+DaCHgjvwyNfdLHdpPedj\ndruAhm3F0BVfbWkIkiTRaiWcsmAlBZq3BUnqN7xGJhXG/f3P+Pj8frsUQ8kHwzfo\nTtqDBSjFmnNJLXecmhsAxPnAnZSZQTuF2oXwWpEDvOI7NBMnLsc/BxQBAoGAHefz\nxtizIH0tWdnn3dS92mKQniu5xrjXtZl/hTSb1/+yZudJfWmKnHvxt+NMmSjxp1jy\n7UYqw2PteKSADyp+G7/NpE+MuiPsOgxWs8JaNTbtpxxgI7VPHW4835YUVzzFG0RS\n+GQCil3PyMcyBcOApRGjxHVJcxzyJ/XyX3/yy9MCgYEAkcUhxCGb6sbv/jigd1w6\nwfP/7IOvz1qDVxWLfpqahejq6FmaFV9NXz9veF2tRQDHNFV8KUfE/lWajJUiNP5j\nu+Hwq82W68pbBoe0nd4fzwBG2XyHTGrw9x2Ww6bmFqhLuEb1krxuSFJgLWvwavYZ\nYmS673PUyncuXccAS3kA4GM=\n-----END PRIVATE KEY-----\n",
//           "client_email": "firebase-adminsdk-6bdda@matajr-40a00.iam.gserviceaccount.com",
//           "client_id": "112269717527421723355",
//           "auth_uri": "https://accounts.google.com/o/oauth2/auth",
//           "token_uri": "https://oauth2.googleapis.com/token",
//           "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
//           "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-6bdda%40matajr-40a00.iam.gserviceaccount.com",
//           "universe_domain": "googleapis.com"
//         },
//       ),
//       [firebaseMessagingScope],
//     );
//     final accessToken = client.credentials.accessToken.data;
//     return accessToken;
//   }
// }