import 'dart:io';

import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

class AppReviewService {
  AppReviewService({InAppReview? inAppReview})
      : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  Future<bool> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        return true;
      }
    } catch (_) {
      // fall back to store listing
    }

    return openStoreListing();
  }

  Future<bool> openStoreListing() async {
    final url = Platform.isIOS
        ? AppConstants.appStoreReviewUrl
        : AppConstants.playStoreReviewUrl;

    if (url.contains('id0000000000')) {
      return false;
    }

    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
