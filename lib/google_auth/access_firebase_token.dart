import 'package:googleapis_auth/auth_io.dart';

class AccessTokenFirebase {
  static String firebaseMessagingScope =
      'https://www.googleapis.com/auth/firebase.messaging';

  Future<String> getAccessToken() async {
    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(
        {
          "type": "service_account",
          "project_id": "matajr-40a00",
          "private_key_id": "09736ca50b019b7cb99c92e5fc5250c20e85487d",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC70QHmJNypEA+G\ntgAc4yJe19Yr08ySpkh8w6JEoSk8W+qnJyKKmEKHwsSlxvyuK4ahbRf++YyywEFB\nwhABYUahdEE7aLOQy7jskN6i+bzS6ZTS+wNZMJm/m45GO3+G3CXmm0h4Y7RprmFO\nNlUo8keFqwkrjhfHdLyEqSkb9P2VG4feHJwFCtGXHBgnDiGZfKHin2f4DlraFIio\ngKjDZHyGq/bjunWu4vwdrMeZ0gLXgHNX9sTcOtOK5Y65ePp35P5pSK0plXF85HaO\nzlycHg+6EWHKemu0JQIlYK9yKon35M/G9+7QixRo1Bbg/qmX/4PCLoZ02IX8DOll\n7OxqFTJrAgMBAAECggEANA2XxKS3wWVxoCjF/DuZNYcFVS1Et+o9EdMYoIO4DYH+\nFWibwqSzX7QD01xEgLMQg6HcMi8QpyPwkhyKWg+PR0UUpTX9+mXz8SCvi6TCiAPz\n2st14Jy/J+MheeaYkBRorrKf0bn0cQvC7S3SyV/ooavHBVrCzWVVsEC/438xXscB\nRtDsG8IKDP7fMbnlO5icR2JvQeqwZVCSWZor/P5RpJvilYW0jFHVmQRREC5gXqkj\n14WcOGLpZhFk+6q1sEzym/x9Oy08zdqgBlal4CBEYeth5PosBcO8W/7IPvd8ga+T\nWOaLA9SR7GY2F9FpmKfvheHHUC6/hoJ6z9WmPFIVwQKBgQD85bkpxphPP367F7vv\neUWQGBz+MhMCFe2y2s4W8pteLcxVDQ6cxn98UEff5l55I7BPmbCXbxZDzlkZ7htQ\n48IaZE636HKO3ZhqeY24VvzJgjaCBinjgNcqA6AaHyiXcBmNyIZaz7bONisdis8T\niP/Cq02EAMqWx+AFMjd7xoJzQQKBgQC+HuJLjYVOdDaCJ4bPXi62oT0U8UXdjDDu\nbHJ+/1sG3gOXP4HEoDiRyBT0YPV1H9Sy9Y1gwBtBWhbo7gOEmGeoVqahSv7f9Qh3\nm7HURWG0r5apKS3EyQQdola2GMf8QMWrQbzrfNthk4jeE/w/zuQgibFujnAax4mF\nYPrYjIK2qwKBgBFZcSp8hVZqdLdBGZOELlGEVfjaVpN+DaCHgjvwyNfdLHdpPedj\ndruAhm3F0BVfbWkIkiTRaiWcsmAlBZq3BUnqN7xGJhXG/f3P+Pj8frsUQ8kHwzfo\nTtqDBSjFmnNJLXecmhsAxPnAnZSZQTuF2oXwWpEDvOI7NBMnLsc/BxQBAoGAHefz\nxtizIH0tWdnn3dS92mKQniu5xrjXtZl/hTSb1/+yZudJfWmKnHvxt+NMmSjxp1jy\n7UYqw2PteKSADyp+G7/NpE+MuiPsOgxWs8JaNTbtpxxgI7VPHW4835YUVzzFG0RS\n+GQCil3PyMcyBcOApRGjxHVJcxzyJ/XyX3/yy9MCgYEAkcUhxCGb6sbv/jigd1w6\nwfP/7IOvz1qDVxWLfpqahejq6FmaFV9NXz9veF2tRQDHNFV8KUfE/lWajJUiNP5j\nu+Hwq82W68pbBoe0nd4fzwBG2XyHTGrw9x2Ww6bmFqhLuEb1krxuSFJgLWvwavYZ\nYmS673PUyncuXccAS3kA4GM=\n-----END PRIVATE KEY-----\n",
          "client_email": "firebase-adminsdk-6bdda@matajr-40a00.iam.gserviceaccount.com",
          "client_id": "112269717527421723355",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-6bdda%40matajr-40a00.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com"
        },
      ),
      [firebaseMessagingScope],
    );
    final accessToken = client.credentials.accessToken.data;
    return accessToken;
  }
}
