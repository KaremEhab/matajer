import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/layout.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../constants/vars.dart';
import '../../models/user_model.dart';
part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterInitialState());

  static RegisterCubit get(context) => BlocProvider.of(context);

  void userRegister({
    required String username,
    String? emirate,
    int? age,
    DateTime? birthdate,
    Gender? gender,
    required String email,
    required String password,
  }) async {
    emit(RegisterLoadingState());

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid == null) {
        emit(RegisterErrorState(error: 'Failed to create user'));
        return;
      }

      await userCreate(
        userId: uid,
        username: username,
        emirate: emirate,
        gender: gender,
        age: age,
        birthdate: birthdate,
        email: email,
      );

      await CacheHelper.saveData(key: 'uId', value: uid);

      emit(RegisterSuccessState(uid)); // <-- emit only AFTER Firestore succeeds
    } on FirebaseAuthException catch (error) {
      if (error.code == 'weak-password') {
        emit(RegisterErrorState(error: 'كلمه السر ضعيفه'));
      } else if (error.code == 'email-already-in-use') {
        emit(RegisterErrorState(error: 'Email already in use'));
      } else {
        emit(RegisterErrorState(error: 'An error occurred, try again later'));
      }
    } catch (e) {
      emit(RegisterErrorState(error: 'An error occurred: $e'));
    }
  }

  Future<void> userCreate({
    required String userId,
    required String username,
    required String email,
    String? imageUrl,
    String? emirate,
    Gender? gender,
    String? phoneNumber,
    bool? phoneVerified,
    bool? isGoogle,
    int? age,
    DateTime? birthdate,
  }) async {
    emit(RegisterCreateUserLoadingState());

    if (birthdate == null || gender == null || age == null || emirate == null) {
      emit(RegisterCreateUserErrorState("Missing required user data"));
      return;
    }
    String? image;

    if (imageUrl != null) {
      image = imageUrl;
    } else {
      image = gender == Gender.male
          ? "https://img.freepik.com/free-psd/3d-illustration-human-avatar-profile_23-2150671122.jpg?ga=GA1.1.41040947.1738942024&semt=ais_items_boosted&w=740"
          : "https://img.freepik.com/free-psd/3d-rendering-hair-style-avatar-design_23-2151869159.jpg?ga=GA1.1.41040947.1738942024&semt=ais_items_boosted&w=740";
    }

    UserModel model = UserModel(
      uId: userId,
      username: username,
      email: email,
      profilePicture: image,
      userType: UserType.buyer,
      hasShop: false,
      phoneVerified: phoneVerified ?? false,
      phoneNumber: phoneNumber ?? "", // prevent crash
      birthdate: birthdate,
      gender: gender,
      age: age,
      emirate: emirate,
      accountCreatedAt: Timestamp.now(),
      activityStatus: UserActivityStatus.online,
      newProductsNotification: true,
      commentsNotification: false,
      reviewsNotification: false,
      ordersNotification: true,
      messagesNotification: true,
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        ...model.toMap(),
        'fcmTokens': [fcmDeviceToken],
      });
      uId = userId;
      await CacheHelper.saveData(key: 'uId', value: userId);
      emit(RegisterCreateUserSuccessState());
    } catch (e) {
      emit(RegisterCreateUserErrorState(e.toString()));
    }
  }

  // Future<String?> getRecaptchaToken() async {
  //   try {
  //     final token = await RecaptchaEnterprise.execute(
  //       RecaptchaAction.custom('phone_auth'),
  //       timeout: 10000,
  //     );
  //     debugPrint('✅ Recaptcha token: $token');
  //     return token;
  //   } catch (e) {
  //     debugPrint('🛑 Recaptcha failed: $e');
  //     return null;
  //   }
  // }

  String phoneNumber = '';
  Future<void> sendOtp({required String phoneNumber}) async {
    emit(RegisterPhoneLoadingState());
    this.phoneNumber = phoneNumber;

    // Optional: trigger reCAPTCHA manually
    // final recaptchaToken = await getRecaptchaToken();
    // if (recaptchaToken == null) {
    //   emit(RegisterPhoneErrorState('Recaptcha failed. Try again.'));
    //   return;
    // }

    // Firebase will trigger its internal reCAPTCHA flow.
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        emit(RegisterPhoneSuccessState());
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('🛑 Phone verification failed: ${e.message}');
        emit(RegisterPhoneErrorState(e.message.toString()));
      },
      codeSent: (String verificationId, int? resendToken) {
        emit(RegisterSendOtpSuccessState(verificationId));
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> verifyPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      emit(RegisterVerifyPhoneLoadingState());
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseFirestore.instance.collection('users').doc(uId).update({
        'phoneNumber': phoneNumber,
        'phoneVerified': true,
      });
      emit(RegisterVerifyPhoneSuccessState());
    } catch (e) {
      log(e.toString());
      emit(RegisterVerifyPhoneErrorState(e.toString()));
    }
  }

  Future<UserCredential> signUpWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> googleSignUp(BuildContext context) async {
    emit(SignUpWithGoogleLoadingState());
    UserCredential userCredential = await signUpWithGoogle();
    try {
      if (userCredential.user != null) {
        uId = userCredential.user!.uid;
        String username =
            userCredential.user!.displayName ??
            userCredential.user!.email ??
            'Anonymous';
        DocumentSnapshot<Map<String, dynamic>>? value = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(uId)
            .get();
        if (!context.mounted) return;
        if (!value.exists) {
          navigateAndFinish(
            context: context,
            screen: SignUp(
              socialInfo: true,
              username: username,
              profilePic: userCredential.user!.photoURL,
              phoneNumber: userCredential.user!.phoneNumber,
              email: userCredential.user!.email!,
              uId: uId,
            ),
          );
        } else {
          emit(SignUpWithGoogleSuccessState());
          navigateAndFinish(context: context, screen: const Layout());
        }
      }
    } catch (error) {
      emit(SignUpWithGoogleErrorState(error: 'something went wrong: $error'));
    }
  }

  Future<UserCredential> signUpWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }

  Future<void> facebookSignUp(BuildContext context) async {
    emit(SignUpWithFacebookLoadingState());
    UserCredential userCredential = await signUpWithFacebook();
    try {
      if (userCredential.user != null) {
        uId = userCredential.user!.uid;
        String username = userCredential.user!.displayName.toString();
        DocumentSnapshot<Map<String, dynamic>>? value = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(uId)
            .get();
        if (!context.mounted) return;
        if (!value.exists) {
          navigateAndFinish(
            context: context,
            screen: SignUp(
              socialInfo: true,
              username: username,
              profilePic: userCredential.user!.photoURL,
              phoneNumber: userCredential.user!.phoneNumber,
              email: userCredential.user!.email!,
              uId: uId,
            ),
          );
        } else {
          emit(SignUpWithFacebookSuccessState());
          navigateAndFinish(context: context, screen: const Layout());
        }
      }
    } catch (error) {
      emit(SignUpWithFacebookErrorState(error: 'something went wrong: $error'));
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential> signUpWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider(
      "apple.com",
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  Future<void> appleSignUp(BuildContext context) async {
    emit(SignUpWithAppleLoadingState());
    UserCredential userCredential = await signUpWithApple();
    try {
      if (userCredential.user != null) {
        uId = userCredential.user!.uid;
        String username = userCredential.user!.displayName.toString();
        DocumentSnapshot<Map<String, dynamic>>? value = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(uId)
            .get();
        if (!context.mounted) return;
        if (!value.exists) {
          navigateAndFinish(
            context: context,
            screen: SignUp(
              socialInfo: true,
              username: username,
              profilePic: userCredential.user!.photoURL,
              phoneNumber: userCredential.user!.phoneNumber,
              email: userCredential.user!.email!,
              uId: uId,
            ),
          );
        } else {
          emit(SignUpWithAppleSuccessState());
          navigateAndFinish(context: context, screen: const Layout());
        }
      }
    } catch (error) {
      emit(SignUpWithAppleErrorState(error: 'something went wrong: $error'));
    }
  }
}
