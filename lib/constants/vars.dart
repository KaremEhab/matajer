import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/cubit/analytics/analytics_cubit.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/cubit/wallet/wallet_cubit.dart';
import 'package:matajer/generated/l10n.dart';
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

enum NotificationTypes {
  chat,
  offer,
  newProduct,
  comment,
  review,
  newOrder,
  orderStatus,
}

// Define variables at the top of your State class
final Map<String, String> emiratesMap = {
  S.current.abu_dhabi: "abu dhabi",
  S.current.dubai: "dubai",
  S.current.sharjah: "sharjah",
  S.current.ajman: "ajman",
  S.current.umm_al_quwain: "umm al-quwain",
  S.current.ras_al_khaimah: "ras al khaimah",
  S.current.fujairah: "fujairah",
  S.current.gharbya: "gharbya",
  S.current.al_ain: "al-ain",
};

Widget buildTag(IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: textColor.withOpacity(0.6)),
      SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor.withOpacity(0.6),
        ),
      ),
    ],
  );
}

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
