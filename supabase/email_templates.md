# WanderWith — Supabase Email Templates

Go to **Supabase Dashboard → Authentication → Email Templates** and paste each template into the corresponding section.

---

## 1. Confirm Signup (OTP Verification)

**Subject:** `Your WanderWith verification code: {{ .Token }}`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0;padding:0;background-color:#f4f6f9;font-family:'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:40px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#448AFF 0%,#64B5F6 100%);padding:36px 32px;text-align:center;">
              <h1 style="margin:0;font-size:28px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">WanderWith</h1>
              <p style="margin:6px 0 0;font-size:13px;color:rgba(255,255,255,0.85);letter-spacing:0.5px;">Travel With Intent</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px 32px 16px;">
              <h2 style="margin:0 0 8px;font-size:22px;font-weight:700;color:#1A1A2E;">Verify your email</h2>
              <p style="margin:0 0 28px;font-size:15px;color:#6B7280;line-height:1.6;">
                Welcome to WanderWith! Use the code below to verify your email address and start planning trips with your crew.
              </p>
              <!-- OTP Code -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <div style="display:inline-block;background-color:#F0F4FF;border:2px dashed #448AFF;border-radius:12px;padding:20px 40px;">
                      <span style="font-size:36px;font-weight:800;color:#448AFF;letter-spacing:8px;font-family:'Courier New',monospace;">{{ .Token }}</span>
                    </div>
                  </td>
                </tr>
              </table>
              <p style="margin:24px 0 0;font-size:13px;color:#9CA3AF;text-align:center;line-height:1.5;">
                This code expires in <strong style="color:#6B7280;">60 minutes</strong>.<br/>
                If you didn't create an account, you can safely ignore this email.
              </p>
            </td>
          </tr>
          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <div style="height:1px;background-color:#F3F4F6;"></div>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:24px 32px 32px;text-align:center;">
              <p style="margin:0;font-size:12px;color:#C0C7D0;">
                &copy; 2026 WanderWith &middot; One trip. One plan. Everyone synced.
              </p>
              <p style="margin:8px 0 0;font-size:11px;color:#D1D5DB;">
                You received this because someone signed up with this email on WanderWith.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## 2. Reset Password

**Subject:** `Reset your WanderWith password`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0;padding:0;background-color:#f4f6f9;font-family:'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:40px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#448AFF 0%,#64B5F6 100%);padding:36px 32px;text-align:center;">
              <h1 style="margin:0;font-size:28px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">WanderWith</h1>
              <p style="margin:6px 0 0;font-size:13px;color:rgba(255,255,255,0.85);letter-spacing:0.5px;">Travel With Intent</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px 32px 16px;">
              <h2 style="margin:0 0 8px;font-size:22px;font-weight:700;color:#1A1A2E;">Reset your password</h2>
              <p style="margin:0 0 28px;font-size:15px;color:#6B7280;line-height:1.6;">
                We received a request to reset the password for your WanderWith account. Tap the button below to choose a new password.
              </p>
              <!-- CTA Button -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <a href="{{ .ConfirmationURL }}"
                       target="_blank"
                       style="display:inline-block;background:linear-gradient(135deg,#448AFF 0%,#2979FF 100%);color:#ffffff;font-size:16px;font-weight:700;text-decoration:none;padding:14px 48px;border-radius:12px;letter-spacing:0.3px;box-shadow:0 4px 14px rgba(68,138,255,0.35);">
                      Reset Password
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:24px 0 0;font-size:13px;color:#9CA3AF;text-align:center;line-height:1.5;">
                This link expires in <strong style="color:#6B7280;">60 minutes</strong>.<br/>
                If you didn't request this, you can safely ignore this email.
              </p>
            </td>
          </tr>
          <!-- Security Note -->
          <tr>
            <td style="padding:0 32px 24px;">
              <div style="background-color:#FFF8F0;border-left:3px solid #FF7043;border-radius:8px;padding:14px 16px;">
                <p style="margin:0;font-size:13px;color:#92400E;line-height:1.5;">
                  🔒 <strong>Security tip:</strong> WanderWith will never ask for your password via email. Only reset your password through this official link.
                </p>
              </div>
            </td>
          </tr>
          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <div style="height:1px;background-color:#F3F4F6;"></div>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:24px 32px 32px;text-align:center;">
              <p style="margin:0;font-size:12px;color:#C0C7D0;">
                &copy; 2026 WanderWith &middot; One trip. One plan. Everyone synced.
              </p>
              <p style="margin:8px 0 0;font-size:11px;color:#D1D5DB;">
                You received this because a password reset was requested for this email.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## 3. Magic Link (Optional — if you enable magic link login)

**Subject:** `Your WanderWith sign-in link`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0;padding:0;background-color:#f4f6f9;font-family:'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:40px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#448AFF 0%,#64B5F6 100%);padding:36px 32px;text-align:center;">
              <h1 style="margin:0;font-size:28px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">WanderWith</h1>
              <p style="margin:6px 0 0;font-size:13px;color:rgba(255,255,255,0.85);letter-spacing:0.5px;">Travel With Intent</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px 32px 16px;">
              <h2 style="margin:0 0 8px;font-size:22px;font-weight:700;color:#1A1A2E;">Sign in to WanderWith</h2>
              <p style="margin:0 0 28px;font-size:15px;color:#6B7280;line-height:1.6;">
                Tap the button below to sign in to your account. No password needed — just one tap.
              </p>
              <!-- CTA Button -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <a href="{{ .ConfirmationURL }}"
                       target="_blank"
                       style="display:inline-block;background:linear-gradient(135deg,#448AFF 0%,#2979FF 100%);color:#ffffff;font-size:16px;font-weight:700;text-decoration:none;padding:14px 48px;border-radius:12px;letter-spacing:0.3px;box-shadow:0 4px 14px rgba(68,138,255,0.35);">
                      Sign In
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:24px 0 0;font-size:13px;color:#9CA3AF;text-align:center;line-height:1.5;">
                This link expires in <strong style="color:#6B7280;">60 minutes</strong> and can only be used once.<br/>
                If you didn't request this, you can safely ignore this email.
              </p>
            </td>
          </tr>
          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <div style="height:1px;background-color:#F3F4F6;"></div>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:24px 32px 32px;text-align:center;">
              <p style="margin:0;font-size:12px;color:#C0C7D0;">
                &copy; 2026 WanderWith &middot; One trip. One plan. Everyone synced.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## 4. Change Email Address

**Subject:** `Confirm your new email for WanderWith`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0;padding:0;background-color:#f4f6f9;font-family:'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:40px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#448AFF 0%,#64B5F6 100%);padding:36px 32px;text-align:center;">
              <h1 style="margin:0;font-size:28px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">WanderWith</h1>
              <p style="margin:6px 0 0;font-size:13px;color:rgba(255,255,255,0.85);letter-spacing:0.5px;">Travel With Intent</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px 32px 16px;">
              <h2 style="margin:0 0 8px;font-size:22px;font-weight:700;color:#1A1A2E;">Confirm your new email</h2>
              <p style="margin:0 0 28px;font-size:15px;color:#6B7280;line-height:1.6;">
                You requested to change the email address linked to your WanderWith account. Tap below to confirm.
              </p>
              <!-- CTA Button -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <a href="{{ .ConfirmationURL }}"
                       target="_blank"
                       style="display:inline-block;background:linear-gradient(135deg,#448AFF 0%,#2979FF 100%);color:#ffffff;font-size:16px;font-weight:700;text-decoration:none;padding:14px 48px;border-radius:12px;letter-spacing:0.3px;box-shadow:0 4px 14px rgba(68,138,255,0.35);">
                      Confirm Email Change
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:24px 0 0;font-size:13px;color:#9CA3AF;text-align:center;line-height:1.5;">
                This link expires in <strong style="color:#6B7280;">60 minutes</strong>.<br/>
                If you didn't request this change, please secure your account immediately.
              </p>
            </td>
          </tr>
          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <div style="height:1px;background-color:#F3F4F6;"></div>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:24px 32px 32px;text-align:center;">
              <p style="margin:0;font-size:12px;color:#C0C7D0;">
                &copy; 2026 WanderWith &middot; One trip. One plan. Everyone synced.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## 5. Invite User

**Subject:** `You're invited to join WanderWith!`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0;padding:0;background-color:#f4f6f9;font-family:'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:40px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#448AFF 0%,#64B5F6 100%);padding:36px 32px;text-align:center;">
              <h1 style="margin:0;font-size:28px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">WanderWith</h1>
              <p style="margin:6px 0 0;font-size:13px;color:rgba(255,255,255,0.85);letter-spacing:0.5px;">Travel With Intent</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px 32px 16px;">
              <h2 style="margin:0 0 8px;font-size:22px;font-weight:700;color:#1A1A2E;">You're invited! ✈️</h2>
              <p style="margin:0 0 28px;font-size:15px;color:#6B7280;line-height:1.6;">
                Someone wants you to join WanderWith — the app where friends plan trips together in real time. Accept the invite to get started.
              </p>
              <!-- CTA Button -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <a href="{{ .ConfirmationURL }}"
                       target="_blank"
                       style="display:inline-block;background:linear-gradient(135deg,#448AFF 0%,#2979FF 100%);color:#ffffff;font-size:16px;font-weight:700;text-decoration:none;padding:14px 48px;border-radius:12px;letter-spacing:0.3px;box-shadow:0 4px 14px rgba(68,138,255,0.35);">
                      Accept Invite
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:24px 0 0;font-size:13px;color:#9CA3AF;text-align:center;line-height:1.5;">
                This invitation expires in <strong style="color:#6B7280;">7 days</strong>.
              </p>
            </td>
          </tr>
          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <div style="height:1px;background-color:#F3F4F6;"></div>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:24px 32px 32px;text-align:center;">
              <p style="margin:0;font-size:12px;color:#C0C7D0;">
                &copy; 2026 WanderWith &middot; One trip. One plan. Everyone synced.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## How to Apply

1. Go to **Supabase Dashboard** → your project
2. Navigate to **Authentication** → **Email Templates**
3. For each template type (Confirm signup, Reset password, Magic link, Change email, Invite user):
   - Replace the **Subject** line
   - Paste the corresponding HTML into the **Body** editor (switch to source/HTML mode)
4. Click **Save**

> **Important:** The variables `{{ .Token }}` and `{{ .ConfirmationURL }}` are Supabase template variables — leave them as-is. Supabase auto-replaces them at send time.

### Redirect URL Configuration

For password reset to work with deep links, also go to:
- **Authentication** → **URL Configuration**
- Add `wanderwith://reset-password` to **Redirect URLs**
- This ensures the reset password button in the email redirects to your Flutter app
