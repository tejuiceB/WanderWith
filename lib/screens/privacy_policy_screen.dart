import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_extensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        title: Text("Privacy Policy", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colors.textPrimary)),
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
        data: _policyText,
      ),
    );
  }

  static const String _policyText = """
# Privacy Policy for WanderWith

**Effective Date:** March 1, 2026  
**Last Updated:** March 1, 2026

Welcome to WanderWith. We are committed to protecting your privacy. This Privacy Policy explains how WanderWith ("we", "us", "our") collects, uses, stores, shares, and protects your personal information when you use our mobile application ("App") and related services.

By using WanderWith, you agree to the collection and use of information in accordance with this policy.

---

## 1. Information We Collect

### 1.1 Personal Information
When you create an account, we collect:
- **Name and Display Name** — to identify you within the app
- **Email Address** — for authentication, communication, and account recovery
- **Profile Picture** — to personalize your profile (stored securely in cloud storage)
- **Username** — your unique public identifier
- **Travel Preferences** — such as budget style, travel vibe, and interests

### 1.2 Trip Data
We collect information related to the trips you create or participate in:
- Destination, dates, budget, and itinerary details
- Trip member lists and roles (admin, member)
- Chat messages, poll votes, and reactions within trips
- Photos and media uploaded to trip galleries
- Expense records shared with trip members
- Reviews and ratings of places visited

### 1.3 Post & Social Data
- Photos, captions, and locations in posts you create
- Likes, comments, and social interactions
- Follower/following relationships

### 1.4 Location Data
- **Device location** — only when you explicitly grant permission, used for nearby place discovery and location-tagged posts
- **Trip locations** — destinations you add to trips
- You can disable location access at any time through your device settings

### 1.5 Usage & Device Data
We automatically collect:
- Device type, operating system, and app version
- Log data, crash reports, and performance metrics
- Feature usage patterns (anonymized) to improve the app
- IP address (for security and fraud prevention)

### 1.6 AI-Generated Data
- When you use AI-powered features, we send anonymized place names and trip details to AI services to generate recommendations
- We do not send your personal identity information to AI providers

---

## 2. Legal Basis for Processing (GDPR)

We process your data under the following legal bases:
- **Consent** — when you create an account, enable location, or opt into features
- **Contract** — to provide the services you signed up for
- **Legitimate Interest** — to improve our services, ensure security, and prevent fraud
- **Legal Obligation** — to comply with applicable laws and regulations

---

## 3. How We Use Your Information

We use the collected data to:
- Provide, maintain, and improve the WanderWith service
- Facilitate trip planning, collaboration, and communication
- Deliver AI-powered travel recommendations and insights
- Process and display your posts, photos, and social interactions
- Send notifications about trip updates, chat messages, and account activity
- Analyze usage patterns to improve features and fix issues
- Ensure the security and integrity of our platform
- Comply with legal obligations

---

## 4. Data Sharing & Third Parties

We share data with these third-party services only as necessary:

| Service | Purpose | Data Shared |
|---------|---------|-------------|
| **Supabase** | Authentication, database, storage | Account data, trip data, media |
| **Google Maps Platform** | Location services, place details | Search queries, coordinates |
| **Google Gemini AI** | Travel recommendations | Anonymized place names, trip context |
| **Google Sign-In** | OAuth authentication | Email, name (from Google account) |

We do **not** sell your personal data to any third party.

---

## 5. International Data Transfers

Your data may be stored and processed in data centers outside your country of residence. Supabase infrastructure is hosted in secure cloud regions. Where data is transferred outside the EEA, we ensure appropriate safeguards are in place in accordance with GDPR requirements.

---

## 6. Data Retention

- **Active accounts** — data is retained for as long as your account is active
- **Deleted accounts** — all personal data is permanently deleted within 30 days of account deletion. This includes profile data, posts, trip memberships, and uploaded media
- **Anonymized analytics** — may be retained indefinitely for statistical purposes
- **Chat messages** — retained for the lifetime of the trip; deleted when the trip is deleted
- **AI enrichment data** — cached for up to 90 days, then refreshed

---

## 7. Your Rights Under GDPR

If you are in the European Economic Area (EEA), you have the right to:
- **Access** — request a copy of the personal data we hold about you
- **Rectification** — request correction of inaccurate or incomplete data
- **Erasure** — request deletion of your personal data ("right to be forgotten")
- **Data Portability** — receive your data in a structured, machine-readable format
- **Restriction** — request that we limit the processing of your data
- **Objection** — object to the processing of your data based on legitimate interests
- **Withdraw Consent** — withdraw your consent at any time without affecting the lawfulness of prior processing

To exercise these rights, contact us at **wanderwithplan@gmail.com**.

---

## 8. Your Rights Under CCPA

If you are a California resident, you have the right to:
- **Know** — what personal information we collect, use, and disclose
- **Delete** — request deletion of your personal information
- **Opt-Out** — opt out of the sale of personal information (we do not sell data)
- **Non-Discrimination** — not be discriminated against for exercising your privacy rights

---

## 9. Children's Privacy

WanderWith is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we discover that we have collected data from a child under 13, we will delete it promptly. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.

---

## 10. Account Deletion

You can delete your account at any time through **Settings > Account > Delete Account**. Upon deletion:
- Your profile, posts, and uploaded media are permanently removed
- Your membership in all trips is revoked
- Chat messages you sent remain visible to trip members but are disassociated from your identity
- This process is irreversible and completed within 30 days

---

## 11. Data Security

We implement industry-standard security measures:
- **Encryption in transit** — all data is transmitted over HTTPS/TLS
- **Encryption at rest** — database and storage are encrypted
- **Access controls** — role-based access with row-level security (RLS) policies
- **Authentication** — secure token-based authentication via Supabase Auth
- **Breach notification** — in the event of a data breach, we will notify affected users within 72 hours as required by GDPR

---

## 12. Cookies & Similar Technologies

The WanderWith mobile app does not use browser cookies. We may use local storage and secure tokens for authentication persistence. Our website (if applicable) may use essential cookies for functionality.

---

## 13. Changes to This Policy

We may update this Privacy Policy from time to time. When we make material changes:
- We will notify you via in-app notification or email
- The "Last Updated" date at the top will be revised
- Continued use of the App after changes constitutes acceptance

---

## 14. Contact Information

For questions, concerns, or to exercise your privacy rights:

- **Email:** wanderwithplan@gmail.com
- **Subject Line:** "Privacy Request — [Your Request]"

We aim to respond to all privacy requests within 30 days.

---

*This privacy policy is designed to comply with the General Data Protection Regulation (GDPR), the California Consumer Privacy Act (CCPA), and other applicable privacy laws.*
""";
}
