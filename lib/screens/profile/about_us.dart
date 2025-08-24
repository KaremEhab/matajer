import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';

class AboutUs extends StatefulWidget {
  const AboutUs({super.key});

  @override
  AboutUsState createState() => AboutUsState();
}

class AboutUsState extends State<AboutUs> {
  final List<String> servicesIconsList = [
    'customer-icon',
    'authentic-icon',
    'secure-icon',
    'shipment-icon',
    'globe-icon',
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> servicesTextsList = [
      S.of(context).customer_centric,
      S.of(context).quality_and_auth,
      S.of(context).secure_payments,
      S.of(context).fast_reliable,
      S.of(context).worldwide_market,
    ];
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
          S.of(context).about_matajer,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
          child: Column(
            spacing: 15,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).about_us_header,
                style: TextStyle(
                  fontSize: 22,
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: lightGreyColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          S.of(context).our_mission,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          spacing: 5,
                          children: [
                            Text(
                              "March 20",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: textColor.withOpacity(0.6),
                              radius: 3,
                            ),
                            Text(
                              "2024",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        Text(
                          "      ${S.of(context).matajer_mission}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        RotatedBox(
                          quarterTurns: lang == 'en' ? 0 : 2,
                          child: SvgPicture.asset("images/mission-quote.svg"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).our_services,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: index == 2 ? 13 : 15,
                                ),
                                decoration: BoxDecoration(
                                  color: lightGreyColor.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: SvgPicture.asset(
                                  width: double.infinity,
                                  height: index == 2 ? 40 : 35,
                                  "images/${servicesIconsList[index]}.svg",
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                servicesTextsList[index],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
