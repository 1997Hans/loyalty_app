# Loyalty App README

## Overview
The Loyalty App is a mobile application built using Flutter (Dart) that integrates with a WooCommerce-powered WordPress website. The app enables customers to earn and redeem loyalty points based on their purchases, providing a seamless shopping experience with real-time point tracking and rewards redemption.

## Key Features

### 1. **User Authentication**
- Modern authentication with support for:
  - Email and Password
  - Google Sign-In (Gmail)
  - Social Media Authentication (Facebook, Apple ID, etc.)
  - Password Reset and Account Recovery

### 2. **Loyalty Points System**
- Earn points automatically based on purchases (conversion rate configurable in WooCommerce settings)
- View current points balance
- Track point-earning history
- Redeem points for discounts or rewards
- Notification system for point updates and redemption confirmations

### 3. **WooCommerce Integration**
- Syncs with WordPress WooCommerce store in real-time
- Displays user-specific order history
- Fetches product data and special loyalty offers

### 4. **Redemption & Rewards**
- Points can be redeemed for discounts on future purchases
- Admin-defined redemption rate for points
- Coupon or discount code generation upon redemption
- View available rewards and past redemptions

### 5. **User Dashboard**
- Display personal details and loyalty status
- View and manage rewards history
- Manage account settings

### 6. **Push Notifications & Alerts**
- Get notified of new promotions and loyalty events
- Real-time updates on earned and redeemed points
- Custom alerts for expiring points or limited-time offers

### 7. **Security & Data Privacy**
- Secure user authentication (OAuth & JWT)
- Encrypted data transmission
- Compliance with GDPR and other relevant data protection laws

## Technical Stack
- **Frontend:** Flutter (Dart)
- **Backend:** WordPress + WooCommerce REST API
- **Authentication:** Firebase Authentication, Social Sign-In APIs
- **Database:** WooCommerce (MySQL-based)
- **API Calls:** REST API for bidirectional sync

## Installation & Setup
1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-repo/loyalty-app.git
   cd loyalty-app
   ```
2. **Install Dependencies**
   ```bash
   flutter pub get
   ```
3. **Set Up Firebase for Authentication**
   - Configure Firebase project
   - Enable Google and Social Sign-In
   - Download and place `google-services.json` in `android/app/`
   - Download and place `GoogleService-Info.plist` in `ios/Runner/`

4. **Configure API Endpoint**
   - Modify `lib/config.dart` with your WooCommerce API base URL:
   ```dart
   const String apiUrl = "https://your-woocommerce-site.com/wp-json/loyalty/v1/";
   ```

5. **Run the App**
   ```bash
   flutter run
   ```

## Future Enhancements
- Add support for additional reward redemption methods
- Implement referral-based loyalty rewards
- Add a chatbot for customer inquiries

## Contribution & Support
Feel free to submit issues or contribute to the project by opening a pull request. Reach out for any queries or feature requests!

---

Let me know if you need further refinements! 🚀

