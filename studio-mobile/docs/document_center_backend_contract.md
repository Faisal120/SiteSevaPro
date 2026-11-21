# Document Center Backend Contract

SiteSevaPro-main now combines the existing JWT-authenticated Cloudinary signing
with a role-scoped document registry:

- `GET /api/documents`
- `POST /api/documents`
- `PATCH /api/documents/{document_id}`
- `DELETE /api/documents/{document_id}`
- `GET /api/documents/{document_id}/download`

The download endpoint redirects to the server-authorized Cloudinary asset URL.
The Flutter client uploads bytes directly to Cloudinary only after obtaining a
short-lived signature from `GET /api/cloudinary/signature`, then stores the
resulting metadata through the document registry.

## Routes

| Method | Route | Roles | Purpose |
| --- | --- | --- | --- |
| `GET` | `/api/documents?site_id=&kind=&q=` | Contractor, Supervisor, Client | List files scoped to the authenticated company and role. |
| `POST` | `/api/documents` | Contractor, Supervisor | Register a file after its signed Cloudinary upload. |
| `PATCH` | `/api/documents/{document_id}` | Contractor | Update sharing and document metadata. |
| `DELETE` | `/api/documents/{document_id}` | Contractor | Remove the registry record and the associated Cloudinary asset. |
| `GET` | `/api/documents/{document_id}/download` | Contractor, Supervisor, Client | Stream or redirect to the authorized document download. |

Binary upload uses the existing `GET /api/cloudinary/signature` route with `folder=siteseva/documents` and `resource_type=image|video|raw`. The Flutter client uploads directly to Cloudinary, then registers the returned asset with `POST /api/documents`.

## Registration payload

```json
{
  "name": "Ground floor electrical drawing",
  "kind": "DRAWING",
  "site_id": "site-123",
  "description": "Issued for site execution",
  "shared_with_client": false,
  "url": "https://res.cloudinary.com/example/raw/upload/v1/file.pdf",
  "secure_url": "https://res.cloudinary.com/example/raw/upload/v1/file.pdf",
  "public_id": "siteseva/documents/file",
  "resource_type": "raw",
  "mime_type": "application/pdf",
  "original_filename": "electrical.pdf",
  "size_bytes": 182400
}
```

## Response shape

`GET /api/documents` returns a JSON array. Each item should include `id`, `name`, `kind`, `site_id`, `site_name`, `url` or `download_url`, `mime_type`, `original_filename`, `size_bytes`, `version`, `created_by_name`, `created_at`, and `shared_with_client`.

## Role and deletion policy

- Contractor: read all company files, upload, share, delete and download.
- Supervisor: read assigned-project files, upload field evidence and download; cannot change client sharing or delete.
- Client: read and download only files explicitly marked `shared_with_client` for assigned projects.

The backend must enforce company, assigned-site and sharing scope server-side. Flutter permission checks are only a UX guard and are not a security boundary.
