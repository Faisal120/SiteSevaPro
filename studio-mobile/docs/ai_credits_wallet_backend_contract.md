# AI Credits Wallet Contract

Feature 16 consumes the existing authenticated Design Wallet endpoints:

- `GET /api/design-wallet`
- `GET /api/design-wallet/transactions`
- `GET /api/design-wallet/purchase/config`
- `GET /api/design-wallet/purchase/my`
- `POST /api/design-wallet/purchase/request`

The purchase request body is:

```json
{
  "pack": "PRO_50",
  "utr": "UPI_TRANSACTION_REFERENCE",
  "note": "optional accounting note"
}
```

The purchase configuration must return trusted pack codes, credit counts,
amounts, `upi_id`, and `payee_name`. The mobile client never calculates packs
or payment destinations itself. Contractor access is required; supervisor and
client users receive an explicit role-restricted response rather than a fake
zero balance.
