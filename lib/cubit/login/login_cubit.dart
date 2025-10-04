import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/register/register_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/auth/login.dart';
import 'package:matajer/screens/auth/phone_number.dart';
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/layout.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../constants/vars.dart';
part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  static LoginCubit get(context) => BlocProvider.of(context);

  void userLogin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      emit(LoginLoadingState());
      var userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      uId = userCredential.user!.uid;
      var user = await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .get();
      if (!user.exists) {
        throw 'الحساب غير موجود';
      }
      await Future.wait([
        // 👇 Replace all old tokens with the new one
        FirebaseFirestore.instance.collection('users').doc(uId).update({
          'fcmTokens': [fcmDeviceToken],
          'activityStatus': UserActivityStatus.online.name,
        }),
        CacheHelper.saveData(key: 'uId', value: uId),
      ]);
      emit(LoginSuccessState(uId));
    } catch (error) {
      if (error is FirebaseAuthException) {
        if (error.code == 'user-not-found') {
          emit(LoginErrorState(error: S.of(context).un_registered_account));
        } else if (error.code == 'wrong-password') {
          emit(LoginErrorState(error: S.of(context).wrong_password));
        } else {
          emit(LoginErrorState(error: S.of(context).something_went_wrong));
        }
      } else {
        emit(LoginErrorState(error: 'An error occurred: $error'));
      }
    }
  }

  Future<void> signInAnonymously(BuildContext context) async {
    emit(SignInWithGuestLoadingState());
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        uId = user.uid;

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uId)
            .get();

        if (!context.mounted) return;

        // Create guest user document if not exists
        if (!doc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(uId).set({
            'uId': uId,
            'username': 'Guest',
            'email': '',
            'profilePicture':
                "https://img.freepik.com/free-psd/3d-illustration-human-avatar-profile_23-2150671122.jpg?ga=GA1.1.41040947.1738942024&semt=ais_items_boosted&w=740",
            'userType': UserType.guest.name,
            'hasShop': false,
            'phoneVerified': false,
            'phoneNumber': '',
            'birthdate': null,
            'age': null,
            'gender': 'male',
            'emirate': '',
            'accountCreatedAt': Timestamp.now(),
            'activityStatus': UserActivityStatus.online.name,
            'fcmTokens': [fcmDeviceToken],
            'isAnonymous': true,
          });
        } else {
          FirebaseFirestore.instance.collection('users').doc(uId).update({
            'fcmTokens': [fcmDeviceToken],
          });
        }

        isGuest = true;

        await CacheHelper.saveData(key: 'uId', value: uId);
        await CacheHelper.saveData(key: 'isGuest', value: isGuest);

        emit(SignInWithGuestSuccessState());
        //
        // // Navigate to main layout
        // navigateAndFinish(context: context, screen: const Layout());
      }
    } catch (e) {
      emit(SignInWithGuestErrorState(error: 'Guest login failed: $e'));
    }
  }

  Future<void> deleteAnonymousGuest(BuildContext context) async {
    try {
      if (isGuest) {
        final uId = currentUserModel.uId;
        print("🔍 Deleting guest with UID: $uId");

        // Step 1: Delete Firestore user doc
        await FirebaseFirestore.instance.collection('users').doc(uId).delete();
        print("✅ Firestore doc deleted");

        // Step 3: Clear locally cached data
        await CacheHelper.removeData(key: 'uId');
        await CacheHelper.removeData(key: 'isGuest');
        isGuest = false;

        emit(DeleteGuestSuccessState());

        // Step 5: Navigate
        if (context.mounted) {
          navigateAndFinish(context: context, screen: const Login());
        }
      } else {
        print("⚠️ Not an anonymous user or already deleted.");
        emit(
          DeleteGuestErrorState(
            error: "User is not anonymous or already deleted.",
          ),
        );
      }
    } catch (e, stack) {
      print("❌ Error deleting guest: $e\n$stack");
      emit(DeleteGuestErrorState(error: 'Error deleting guest: $e'));
    }
  }

  Future<UserCredential> signInWithGoogle() async {
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

  Future<void> googleSignIn(BuildContext context) async {
    emit(SignInWithGoogleLoadingState());
    UserCredential userCredential = await signInWithGoogle();
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
          await Future.wait([
            FirebaseFirestore.instance.collection('users').doc(uId).update({
              'fcmTokens': [fcmDeviceToken],
              'activityStatus': UserActivityStatus.online.name,
            }),
            CacheHelper.saveData(key: 'uId', value: uId),
          ]);
          emit(SignInWithGoogleSuccessState());
          if (!context.mounted) return;
          navigateAndFinish(context: context, screen: const Layout());
        }
      }
    } catch (error) {
      emit(SignInWithGoogleErrorState(error: 'something went wrong: $error'));
    }
  }

  Future<UserCredential> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }

  Future<void> facebookSignIn(BuildContext context) async {
    emit(SignInWithFacebookLoadingState());
    UserCredential userCredential = await signInWithFacebook();
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
            screen: const PhoneNumberPage(
              hideBackButton: true,
              displaySkipBtn: true,
            ),
          );
          await RegisterCubit.get(context).userCreate(
            username: username,
            email: userCredential.user!.email!,
            userId: uId,
          );
        } else {
          await Future.wait([
            FirebaseFirestore.instance.collection('users').doc(uId).update({
              'fcmTokens': [fcmDeviceToken],
              'activityStatus': UserActivityStatus.online.name,
            }),
            CacheHelper.saveData(key: 'uId', value: uId),
          ]);
          emit(SignInWithFacebookSuccessState());
          if (!context.mounted) return;
          navigateAndFinish(context: context, screen: const Layout());
        }
      }
    } catch (error) {
      emit(SignInWithFacebookErrorState(error: 'something went wrong: $error'));
    }
  }

  // https://matajr-40a00.firebaseapp.com/__/auth/handler
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
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

  Future<UserCredential> signInWithApple() async {
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
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  Future<void> appleSignIn(BuildContext context) async {
    emit(SignInWithAppleLoadingState());
    UserCredential userCredential = await signInWithApple();
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
          await Future.wait([
            FirebaseFirestore.instance.collection('users').doc(uId).update({
              'fcmTokens': [fcmDeviceToken],
              'activityStatus': UserActivityStatus.online.name,
            }),
            CacheHelper.saveData(key: 'uId', value: uId),
          ]);
          emit(SignInWithAppleSuccessState());
          if (!context.mounted) return;
          navigateAndFinish(context: context, screen: const Layout());
        }
      }
    } catch (error) {
      emit(SignInWithAppleErrorState(error: 'something went wrong: $error'));
    }
  }

  void forgetPassword({required String email}) async {
    try {
      emit(LoginForgetPasswordLoadingState());
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emit(LoginForgetPasswordSuccessState());
    } catch (error) {
      if (error is FirebaseAuthException) {
        if (error.code == 'user-not-found') {
          emit(
            LoginForgetPasswordErrorState(
              error: 'هذا البريد الالكتروني غير مسجل',
            ),
          );
        } else {
          emit(
            LoginForgetPasswordErrorState(error: 'حدث خطأ ما,حاول مره اخري'),
          );
        }
      } else {
        emit(LoginForgetPasswordErrorState(error: 'An error occurred: $error'));
      }
    }
  }
}
