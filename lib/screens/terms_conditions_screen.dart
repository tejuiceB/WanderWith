import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
      ),
      body: const Markdown(
        data: """
# Terms and Conditions for WanderWith

**Last Updated:** February 3, 2026

Please read these Terms and Conditions carefully before using the WanderWith mobile application.

## 1. Acceptance of Terms

By accessing or using WanderWith, you agree to be bound by these Terms. If you disagree with any part of the terms, you may not access the service.

## 2. User Accounts

- You are responsible for safeguarding the password that you use to access the service.
- You agree not to disclose your password to any third party.
- You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.

## 3. Content and Conduct

- **User Content**: You retain ownership of the content you create (trips, polls, chats). By posting content, you grant us a license to use it to provide the service.
- **Prohibited Conduct**: You agree not to use the app for any unlawful purpose, to harass others, or to post objectionable content. We reserve the right to ban users who violate these rules.

## 4. Intellectual Property

The WanderWith app and its original content, features, and functionality are and will remain the exclusive property of WanderWith and its licensors.

## 5. Limitation of Liability

In no event shall WanderWith, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the Service.

## 6. Trip Planning Disclaimer

WanderWith is a tool for planning and coordination. We are not a travel agency. We are not responsible for:
- Cancellations or changes to your travel plans.
- The safety or quality of accommodations or activities.
- Disputes between trip members.

## 7. Changes

We reserve the right, at our sole discretion, to modify or replace these Terms at any time. We will provide notice of any significant changes.

## 8. Contact Us

If you have any questions about these Terms, please contact us at:
**legal@tejuice.fun**
""",
      ),
    );
  }
}
