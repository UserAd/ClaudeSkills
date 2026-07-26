# HTTP API: {scope}

> **Owner:** SVC-XX | **Base Path:** /api/v1 | **Auth:** api_key | jwt | none

## Endpoints

### GET /examples

| Field | Value |
|-------|-------|
| **Consumers** | external, SVC-YY |
| **Auth** | api_key |
| **Response Schema** | [examples-response.json](../../schemas/api/examples-response.json) |

**Request:**

```http
GET /api/v1/examples?limit=10
Authorization: Bearer {api_key}
```

**Response:**

```json
{
  "data": [
    {"id": 1, "name": "Example"}
  ],
  "meta": {
    "total": 100,
    "page": 1
  }
}
```

### POST /examples

| Field | Value |
|-------|-------|
| **Consumers** | external |
| **Auth** | api_key |
| **Request Schema** | [example-request.json](../../schemas/api/example-request.json) |

**Request:**

```json
{
  "name": "New Example",
  "type": "default"
}
```

**Response:**

```json
{
  "id": 123,
  "name": "New Example",
  "created_at": "2025-01-15T10:30:00Z"
}
```

## Error Responses

| Code | Description |
|------|-------------|
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Invalid or missing auth |
| 404 | Not Found - Resource doesn't exist |
| 500 | Internal Server Error |
