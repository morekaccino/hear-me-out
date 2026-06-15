import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SubscriptionTier { free, pro, teacher }

class SubscriptionService {
  static const String proProductId = 'com.hearmeout.pro.monthly';
  static const String teacherProductId = 'com.hearmeout.teacher.monthly';

  SubscriptionTier currentTier = SubscriptionTier.free;

  Future<void> initialize() async {
    // InAppPurchase.instance.purchaseStream.listen(_handlePurchase);
    // Load cached subscription status
  }

  Future<bool> purchasePro() async {
    // In production: call InAppPurchase.instance.buyNonConsumable()
    // Simulated success:
    currentTier = SubscriptionTier.pro;
    return true;
  }

  Future<bool> purchaseTeacher() async {
    currentTier = SubscriptionTier.teacher;
    return true;
  }

  Future<void> restorePurchases() async {
    // InAppPurchase.instance.restorePurchases()
  }

  bool get isPro => currentTier != SubscriptionTier.free;
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});
