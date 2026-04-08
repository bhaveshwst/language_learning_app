# Live Session QA + Rollout Checklist

## Device matrix

- Android physical device on Wi-Fi
- Android physical device on mobile data
- iOS physical device on Wi-Fi
- iOS physical device on mobile data

## Functional test cases

- Tutor joins first, student joins after.
- Student joins first and sees waiting state.
- 2+ students join same tutor slot.
- Unbooked student cannot join.
- Student with overlapping booking is blocked.
- Student/tutor join outside time window is blocked.
- Permission denied (camera/mic) shows recoverable UI.
- Background/foreground app during call keeps room stable.
- Internet drop and reconnect recovers or shows retry.
- Tutor leaves early and session ends for students.

## Security checks

- No ZEGO server secret or app sign in source control.
- Join API returns only expiring token.
- Token expiry handling prompts re-join.
- Logs do not include full token payload.

## Rollout plan

1. Ship behind remote feature flag (`live_session_enabled`).
2. Enable for internal testers only.
3. Enable for 5% of users and monitor:
   - join success rate
   - average call duration
   - crash-free sessions
4. Move to 25%, then 100% after 48h stable metrics.
