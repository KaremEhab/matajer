import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/screens/paypal/success_payment.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalPage extends StatefulWidget {
  const PayPalPage({
    super.key,
    required this.paypalLink,
    required this.shopId,
    required this.deliveryTime,
  });

  final String paypalLink, shopId;
  final num deliveryTime;

  @override
  State<PayPalPage> createState() => _PayPalPageState();
}

class _PayPalPageState extends State<PayPalPage> {
  late final WebViewController controller;

  @override
  void initState() {
    controller = WebViewController()..loadRequest(Uri.parse(widget.paypalLink));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PayPal"),
        centerTitle: true,
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (await controller.canGoBack()) {
                    await controller.goBack();
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text("No back history found")),
                    );
                    return;
                  }
                },
                icon: const Icon(Icons.keyboard_arrow_left),
              ),
              IconButton(
                onPressed: () async {
                  controller.reload();
                },
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (await controller.canGoForward()) {
                    await controller.goForward();
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text("No forward history found")),
                    );
                    return;
                  }
                },
                icon: const Icon(Icons.keyboard_arrow_right),
              ),
            ],
          ),
        ],
      ),
      body: PostImagesWeb(
        controller: controller,
        shopId: widget.shopId,
        deliveryTime: widget.deliveryTime,
      ),
    );
  }
}

class PostImagesWeb extends StatefulWidget {
  const PostImagesWeb({
    super.key,
    required this.controller,
    required this.shopId,
    required this.deliveryTime,
  });

  final WebViewController controller;
  final String shopId;
  final num deliveryTime;

  @override
  State<PostImagesWeb> createState() => _PostImagesWebState();
}

class _PostImagesWebState extends State<PostImagesWeb> {
  var loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
    widget.controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              loadingPercentage = 0;
            });
          },
          onProgress: (progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onPageFinished: (url) async {
            setState(() {
              loadingPercentage = 100;
            });
            if (url.contains('/capture')) {
              // Inject JavaScript to get the body content
              final result = await widget.controller
                  .runJavaScriptReturningResult('document.body.innerText;');
              String bodyContent = result as String;
              log('Body Content: $bodyContent');
              if (!context.mounted) return;
              slideAnimation(
                context: context,
                destination: SuccessPayment(
                  orderId: bodyContent,
                  shopId: widget.shopId,
                  deliveryTime: widget.deliveryTime,
                ),
                leftSlide: true,
              );
            }
          },
        ),
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        "SnackBar",
        onMessageReceived: (message) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message.message)));
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: widget.controller),
        if (loadingPercentage < 100)
          LinearProgressIndicator(value: loadingPercentage / 100),
      ],
    );
  }

  // Map<String, dynamic> _extractMapData(Object body) {
  //   Map<String, dynamic> data = {};
  //   // parse the body to extract the map data
  //   body
  //   return data;
  // }
}
