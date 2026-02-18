import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
      ),
      body: const Markdown(
        data: """
# Privacy Policy for WanderWith

**Last Updated:** February 3, 2026

Welcome to WanderWith! Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our mobile application.

## 1. Information We Collect

### 1.1 Personal Information
When you create an account, we may collect:
- **Name**: To identify you within the app.
- **Email Address**: For authentication and communication.
- **Profile Picture**: To personalize your profile (stored securely).
- **Travel Preferences**: Such as budget style and vibe, to enhance your experience.

### 1.2 Trip Data
We collect information related to the trips you create or join:
- Destination, dates, and budget.
- Members of the trip.
- Chat messages and poll votes within the trip.

### 1.3 Usage Data
We automatically collect usage data to improve our app performance, including:
- Device type.
- Operating system.
- Log data and crash reports.

## 2. How We Use Your Information

We use your data to:
- Provide and maintain the WanderWith service.
- Facilitate trip planning and collaboration.
- Suggest AI-powered travel recommendations.
- Improve usage and fix technical issues.
- Communicate with you regarding updates or support.

## 3. Data Storage and Security

We use **Supabase** for secure authentication and data storage.
- **Data Encryption**: Your data is encrypted in transit and at rest.
- **Access Control**: You control who sees your trip data (members only for private trips).

## 4. Third-Party Services

We may use third-party services like:
- **Google Maps**: For location services.
- **OpenAI / Gemini**: For AI travel assistance (anonymized queries).

## 5. Your Rights

You have the right to:
- Access the personal data we hold about you.
- Request the correction of inaccurate data.
- Delete your account and all associated data.

## 6. Contact Us

If you have any questions about this Privacy Policy, please contact us at:
**support@tejuice.fun**
""",
      ),
    );
  }
}
