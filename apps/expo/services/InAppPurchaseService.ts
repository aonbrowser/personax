import { Platform } from 'react-native';
import * as InAppPurchases from 'expo-in-app-purchases';
import RNIap, { 
  Product, 
  Subscription,
  PurchaseError,
  Purchase,
  SubscriptionPurchase,
  finishTransaction,
  purchaseErrorListener,
  purchaseUpdatedListener,
  getProducts,
  getSubscriptions,
  requestSubscription,
  requestPurchase
} from 'react-native-iap';

// Product IDs for different platforms
const PRODUCT_IDS = {
  ios: {
    subscriptions: [
      'com.personax.standard.monthly',
      'com.personax.extra.monthly'
    ],
    payg: [
      'com.personax.self.analysis',
      'com.personax.other.analysis',
      'com.personax.relationship.analysis'
    ]
  },
  android: {
    subscriptions: [
      'standard_monthly',
      'extra_monthly'
    ],
    payg: [
      'self_analysis',
      'other_analysis',
      'relationship_analysis'
    ]
  }
};

interface IAPService {
  initConnection(): Promise<boolean>;
  getSubscriptions(): Promise<Subscription[]>;
  getProducts(): Promise<Product[]>;
  purchaseSubscription(productId: string): Promise<any>;
  purchaseProduct(productId: string): Promise<any>;
  restorePurchases(): Promise<any>;
  validatePurchase(purchase: any): Promise<boolean>;
}

class InAppPurchaseService implements IAPService {
  private purchaseUpdateSubscription: any = null;
  private purchaseErrorSubscription: any = null;
  private isInitialized = false;

  async initConnection(): Promise<boolean> {
    if (Platform.OS === 'web') {
      console.log('In-App Purchases not supported on web');
      return false;
    }

    try {
      await RNIap.initConnection();
      this.isInitialized = true;

      // Set up purchase listeners
      this.purchaseUpdateSubscription = purchaseUpdatedListener(
        async (purchase: Purchase | SubscriptionPurchase) => {
          console.log('Purchase updated:', purchase);
          
          // Validate purchase with backend
          const isValid = await this.validatePurchase(purchase);
          
          if (isValid) {
            // Acknowledge purchase
            await finishTransaction({ purchase, isConsumable: false });
            console.log('Purchase acknowledged');
          }
        }
      );

      this.purchaseErrorSubscription = purchaseErrorListener(
        (error: PurchaseError) => {
          console.error('Purchase error:', error);
        }
      );

      return true;
    } catch (error) {
      console.error('Failed to initialize IAP:', error);
      return false;
    }
  }

  async getSubscriptions(): Promise<Subscription[]> {
    if (!this.isInitialized) {
      await this.initConnection();
    }

    const productIds = Platform.OS === 'ios' 
      ? PRODUCT_IDS.ios.subscriptions 
      : PRODUCT_IDS.android.subscriptions;

    try {
      const subscriptions = await RNIap.getSubscriptions(productIds);
      console.log('Available subscriptions:', subscriptions);
      return subscriptions;
    } catch (error) {
      console.error('Error getting subscriptions:', error);
      return [];
    }
  }

  async getProducts(): Promise<Product[]> {
    if (!this.isInitialized) {
      await this.initConnection();
    }

    const productIds = Platform.OS === 'ios' 
      ? PRODUCT_IDS.ios.payg 
      : PRODUCT_IDS.android.payg;

    try {
      const products = await RNIap.getProducts(productIds);
      console.log('Available products:', products);
      return products;
    } catch (error) {
      console.error('Error getting products:', error);
      return [];
    }
  }

  async purchaseSubscription(productId: string): Promise<any> {
    if (!this.isInitialized) {
      await this.initConnection();
    }

    try {
      if (Platform.OS === 'ios') {
        // iOS subscription purchase
        const purchase = await requestSubscription({
          sku: productId,
          andDangerouslyFinishTransactionAutomaticallyIOS: false
        });
        return purchase;
      } else {
        // Android subscription purchase
        const purchase = await requestSubscription({
          sku: productId,
          // For Android, we need to specify subscription offers
          subscriptionOffers: [{
            sku: productId,
            offerToken: '' // Will be filled by Google Play
          }]
        });
        return purchase;
      }
    } catch (error) {
      console.error('Subscription purchase error:', error);
      throw error;
    }
  }

  async purchaseProduct(productId: string): Promise<any> {
    if (!this.isInitialized) {
      await this.initConnection();
    }

    try {
      const purchase = await requestPurchase({
        sku: productId,
        andDangerouslyFinishTransactionAutomaticallyIOS: false
      });
      return purchase;
    } catch (error) {
      console.error('Product purchase error:', error);
      throw error;
    }
  }

  async restorePurchases(): Promise<any> {
    if (!this.isInitialized) {
      await this.initConnection();
    }

    try {
      const purchases = await RNIap.getAvailablePurchases();
      console.log('Restored purchases:', purchases);
      
      // Process each restored purchase
      for (const purchase of purchases) {
        await this.validatePurchase(purchase);
      }
      
      return purchases;
    } catch (error) {
      console.error('Restore purchases error:', error);
      throw error;
    }
  }

  async validatePurchase(purchase: any): Promise<boolean> {
    try {
      // Send purchase receipt to backend for validation
      const response = await fetch('http://localhost:8080/v1/payment/validate-purchase', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': 'test@test.com' // Get from auth context
        },
        body: JSON.stringify({
          platform: Platform.OS,
          productId: purchase.productId,
          transactionId: purchase.transactionId,
          receipt: purchase.transactionReceipt,
          purchaseToken: purchase.purchaseToken // Android specific
        })
      });

      const result = await response.json();
      return result.valid;
    } catch (error) {
      console.error('Purchase validation error:', error);
      return false;
    }
  }

  cleanup() {
    if (this.purchaseUpdateSubscription) {
      this.purchaseUpdateSubscription.remove();
    }
    if (this.purchaseErrorSubscription) {
      this.purchaseErrorSubscription.remove();
    }
    RNIap.endConnection();
  }
}

export default new InAppPurchaseService();