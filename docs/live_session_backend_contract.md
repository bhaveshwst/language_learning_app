# Live Session Backend Contract

This app now calls these endpoints for ZEGO live sessions.

## 1) Join Session

- **URL**: `POST /live-session/join`
- **Auth**: bearer token (existing app auth)
- **Request body**:

```json
{
  "actor_type": "student",
  "actor_id": "student_uuid",
  "tutor_id": "tutor_uuid",
  "slot_id": "slot_or_session_id",
  "date": "2026-04-05",
  "start_time": "15:00:00",
  "end_time": "15:30:00",
  "wait_for_host": true
}
```

- **Validation rules**:
  - `actor_type` in `student|tutor`
  - caller identity must match JWT subject
  - slot must belong to tutor/date/time
  - student must have booking for the slot
  - student cannot join if another booked slot overlaps current session
  - allow join only in window: `slot_start - 5 min` to `slot_end + 10 min`

- **Success response** (`200`):

```json
{
  "detail": "ok",
  "data": {
    "room_id": "tutor_uuid_2026-04-05_15:00:00_15:30:00",
    "token": "ZEGO_SHORT_LIVED_TOKEN",
    "user_id": "student_uuid",
    "user_name": "Student Name",
    "role": "student",
    "can_enter_room": false,
    "host_joined": false,
    "waiting_message": "Tutor has not joined yet. Please wait.",
    "expires_at": "2026-04-05T09:22:10Z"
  }
}
```

- **Error responses**:
  - `401` unauthorized
  - `403` booking/ownership mismatch
  - `409` overlapping active booking
  - `422` outside join window
  - `500` token generation failure

## 2) Session Status

- **URL**: `POST /live-session/status`
- **Request body**: same identity fields (`actor_id`, `slot_id`, `tutor_id`)
- **Response**: `host_joined`, `can_enter_room`, `session_state`

## 3) End Session

- **URL**: `POST /live-session/end`
- **Auth**: bearer token (existing app auth)
- **Request body**:

```json
{
  "tutor_id": "tutor_uuid",
  "slot_id": "slot_or_session_id",
  "room_id": "room_id",
  "actor_id": "user_uuid"
}
```

- **`actor_id`**: must match the authenticated user (same id as join response `user_id`). The app sends this for **both** tutor and student when they leave the ZEGO live UI.

- **Behavior (backend must branch on `actor_id`)**:
  - **`actor_id` is the tutor** for this slot: treat as **host ended session** — mark live/session ended for the slot (or equivalent), update `host_joined` / status so join/status reflect “ended”, append audit.
  - **`actor_id` is a student** with a booking: treat as **participant leave only** — record leave/attendance for that student, **do not** end the class for the tutor or other students; ZEGO room may still be active until the host leaves.

- **Validation**:
  - JWT subject must match `actor_id`.
  - `tutor_id`, `slot_id`, `room_id` must identify the same slot the user was in.

## Security Requirements

- Keep ZEGO `app_sign` and server secret in backend secret manager only.
- Never return ZEGO secret to Flutter.
- Generate short-lived room token (recommended <= 15 min).
- Rate-limit join endpoint and log suspicious retries.
