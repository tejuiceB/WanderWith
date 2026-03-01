import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_extensions.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        title: Text("Terms & Conditions", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.iconDefault),
      ),
      body: Markdown(
        styleSheet: MarkdownStyleSheet(
          h1: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
          h2: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
          h3: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
          p: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary, height: 1.6),
          listBullet: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
        ),
        data: _termsText,
      ),
    );
  }

  static const String _termsText = """
# Terms and Conditions for WanderWith

**Effective Date:** March 1, 2026  
**Last Updated:** March 1, 2026

Please read these Terms and Conditions ("Terms") carefully before using the WanderWith mobile application ("App") operated by WanderWith ("we", "us", "our").

By accessing or using WanderWith, you agree to be bound by these Terms. If you disagree with any part of the Terms, you may not access the service.

---

## 1. Acceptance of Terms

By creating an account, accessing, or using WanderWith, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy. These Terms apply to all visitors, users, and others who access or use the App.

---

## 2. Account Registration

### 2.1 Eligibility
- You must be at least 13 years of age to use WanderWith
- If you are under 18, you must have parental or guardian consent
- You may only create one account per person

### 2.2 Account Security
- You are responsible for maintaining the confidentiality of your account credentials
- You must provide accurate and complete registration information
- You agree to update your information to keep it current
- You must notify us immediately of any unauthorized use of your account
- We are not liable for any loss arising from unauthorized use of your account

---

## 3. User Content

### 3.1 Ownership
You retain all ownership rights to the content you create, including trips, posts, photos, messages, reviews, and other materials ("User Content").

### 3.2 License to WanderWith
By posting User Content, you grant WanderWith a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, and display your User Content solely for the purpose of operating and providing the App's services. This license ends when you delete your content or account.

### 3.3 Prohibited Content
You agree not to post content that:
- Is unlawful, harmful, threatening, abusive, harassing, defamatory, or invasive of privacy
- Contains sexually explicit material or promotes violence
- Infringes any intellectual property rights of others
- Contains malware, viruses, or harmful code
- Is spam, advertising, or unauthorized commercial communication
- Impersonates any person or entity
- Contains personal information of others without their consent

---

## 4. Prohibited Conduct

You agree not to:
- Use the App for any illegal purpose or in violation of any laws
- Harass, bully, intimidate, or threaten other users
- Create fake accounts or impersonate others
- Attempt to gain unauthorized access to other users' accounts or data
- Scrape, crawl, or use automated means to access the App
- Interfere with or disrupt the App's infrastructure
- Reverse engineer, decompile, or disassemble any part of the App
- Use the App to distribute unsolicited communications (spam)
- Circumvent any security or access controls

---

## 5. Trip Planning Disclaimer

**WanderWith is a planning and collaboration tool, NOT a travel agency.**

We are not responsible for:
- The accuracy of travel information, recommendations, or AI-generated suggestions
- Cancellations, changes, or disruptions to your travel plans
- The safety, quality, or legality of accommodations, activities, or transportation
- Disputes between trip members
- Weather conditions, natural disasters, or other circumstances beyond our control
- Financial losses related to travel bookings or arrangements
- Personal injury or property damage during travel

AI-powered recommendations are provided for informational purposes only and should be verified independently. Always exercise your own judgment when making travel decisions.

---

## 6. Intellectual Property

The WanderWith App, including its design, features, code, branding, logos, and original content, is the exclusive property of WanderWith and its licensors. You may not:
- Copy, modify, or distribute any part of the App
- Use our trademarks or branding without written permission
- Create derivative works based on the App

---

## 7. Third-Party Services

WanderWith integrates with third-party services including:
- **Google Maps Platform** — for location services and place information
- **Google Gemini AI** — for AI-powered travel recommendations
- **Supabase** — for authentication and data infrastructure
- **Google Sign-In** — for OAuth authentication

Your use of these services is subject to their respective terms and conditions. WanderWith is not responsible for the actions or policies of third-party service providers.

---

## 8. Account Suspension & Termination

### 8.1 By You
You may delete your account at any time through the App's Settings. Upon deletion, your data will be permanently removed as described in our Privacy Policy.

### 8.2 By Us
We may suspend or terminate your account if you:
- Violate these Terms or our Community Guidelines
- Engage in prohibited conduct
- Create risk or legal exposure for WanderWith
- Post prohibited content

We will make reasonable efforts to notify you before suspension. In cases of severe violations, immediate termination may occur without prior notice.

### 8.3 Effect of Termination
Upon termination, your right to use the App ceases immediately. We may retain certain data as required by law or for legitimate business purposes.

---

## 9. DMCA / Copyright Policy

We respect intellectual property rights. If you believe content on WanderWith infringes your copyright:
- Send a notice to **wanderwithplan@gmail.com** with:
  - Description of the copyrighted work
  - Location of the infringing content in the App
  - Your contact information
  - A statement of good faith belief
  - A statement of accuracy under penalty of perjury

We will investigate and respond to valid DMCA notices promptly.

---

## 10. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY LAW:

- WanderWith is provided "AS IS" and "AS AVAILABLE" without warranties of any kind
- We do not warrant that the App will be uninterrupted, secure, or error-free
- In no event shall WanderWith be liable for any indirect, incidental, special, consequential, or punitive damages
- Our total aggregate liability shall not exceed the amount you paid to WanderWith in the 12 months preceding the claim, or \$100, whichever is greater

### 10.1 Indemnification
You agree to indemnify and hold harmless WanderWith and its officers, directors, employees, and agents from any claims, damages, or expenses arising from your use of the App or violation of these Terms.

---

## 11. Dispute Resolution

### 11.1 Governing Law
These Terms shall be governed by and construed in accordance with the laws of India, without regard to conflict of law principles.

### 11.2 Informal Resolution
Before filing a formal dispute, you agree to contact us at **wanderwithplan@gmail.com** to attempt informal resolution. We will make good faith efforts to resolve disputes within 30 days.

### 11.3 Class Action Waiver
You agree that any dispute resolution proceedings will be conducted only on an individual basis and not in a class, consolidated, or representative action.

---

## 12. Modifications to Terms

We reserve the right to modify these Terms at any time. When we make material changes:
- We will provide at least 30 days' notice via in-app notification or email
- The "Last Updated" date will be revised
- Continued use of the App after the effective date constitutes acceptance of the modified Terms
- If you disagree with the changes, you may delete your account before the effective date

---

## 13. Severability

If any provision of these Terms is held to be invalid or unenforceable, the remaining provisions shall continue in full force and effect. The invalid provision will be modified to the minimum extent necessary to make it valid and enforceable.

---

## 14. Entire Agreement

These Terms, together with our Privacy Policy, constitute the entire agreement between you and WanderWith regarding use of the App, superseding any prior agreements.

---

## 15. Contact Information

For questions about these Terms:

- **Email:** wanderwithplan@gmail.com
- **Subject Line:** "Terms Question — [Your Topic]"

---

*Thank you for using WanderWith. Travel safe, plan well, and make memories!*
""";
}
