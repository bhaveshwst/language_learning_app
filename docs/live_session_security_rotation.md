# Live Session Secret Rotation Steps

Use these steps immediately because credentials were previously exposed outside the app.

## Rotate in ZEGO Console

1. Generate a new `Server Secret` and `App Sign`.
2. Revoke old tokens and old secret material.
3. Update backend secret manager values only.

## Backend changes

- Ensure `/live-session/join` issues short-lived ZEGO tokens server-side.
- Token TTL recommended: 10-15 minutes.
- Do not log full token in API logs.

## Flutter changes (already applied)

- App reads ZEGO runtime settings from `--dart-define`:
  - `ZEGO_APP_ID`
- No server secret usage in Flutter.

Run example:

```bash
flutter run \
  --dart-define=ZEGO_APP_ID=123456789
```

For production CI/CD, inject these with environment-specific secrets and never commit them to git.
