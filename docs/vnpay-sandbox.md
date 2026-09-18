# VNPay Sandbox

EduMarket only supports the VNPay Sandbox endpoint. Configure these values in `backend/.env`; do not commit merchant credentials.

```dotenv
VNPAY_TMN_CODE=your_sandbox_terminal_code
VNPAY_HASH_SECRET=your_sandbox_hash_secret
VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=http://localhost:4000/api/payments/vnpay/return
```

The server creates a `PENDING_PAYMENT` VNPAY order at `POST /api/payments/vnpay/create`. Its returned `paymentUrl` is the only URL that should be opened for Sandbox payment. The backend calculates the amount, signs the request, and creates immutable order items; clients must not supply price or amount.

Configure the VNPay Sandbox IPN URL to the public HTTPS address:

```text
https://your-public-host/api/payments/vnpay/ipn
```

For local testing, expose the backend temporarily through an HTTPS tunnel and use that tunnel URL for both the return and IPN addresses. Do not use a production merchant code or secret.

Manual Sandbox verification:

1. Register/login as a customer and add a published course to the cart.
2. Fetch a CSRF token, then call `POST /api/payments/vnpay/create` with the session cookie and CSRF header.
3. Open the returned `paymentUrl` and complete a Sandbox success case.
4. Confirm the return/IPN response shows `PAID` and `SUCCESS`, and that one ACTIVE entitlement exists per purchased course.
5. Replay the same IPN URL: it must return `RspCode: "02"` and create no extra entitlement.
6. Complete a Sandbox cancellation/failure case and verify `CANCELLED` plus `FAILED` payment status and a `PAYMENT_FAILED` audit log.

The callbacks validate the VNPay HMAC-SHA512 signature, transaction reference, stored order amount (multiplied by 100 as VNPay requires), and VNPAY payment method before any state change.
