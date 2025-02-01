;; Define constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AGREEMENT-NOT-FOUND (err u101)) 
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-PAYMENT-NOT-FOUND (err u103))
(define-constant ERR-PAYMENT-ALREADY-CONFIRMED (err u104))

;; Define data vars
(define-data-var next-agreement-id uint u0)
(define-data-var next-payment-id uint u0)

;; Define data maps
(define-map agreements
    { agreement-id: uint }
    {
        landlord: principal,
        tenant: principal,
        monthly-rent: uint,
        security-deposit: uint,
        start-date: uint,
        end-date: uint,
        active: bool,
        total-paid: uint,
        last-payment-date: uint
    }
)

(define-map payments
    { agreement-id: uint, payment-id: uint }
    {
        amount: uint,
        date: uint,
        confirmed: bool,
        payer: principal,
        payment-type: (string-utf8 20)
    }
)

;; Create new rental agreement
(define-public (create-agreement (tenant principal) (monthly-rent uint) (security-deposit uint) (start-date uint) (end-date uint))
    (let
        (
            (agreement-id (var-get next-agreement-id))
        )
        (map-set agreements
            { agreement-id: agreement-id }
            {
                landlord: tx-sender,
                tenant: tenant,
                monthly-rent: monthly-rent,
                security-deposit: security-deposit, 
                start-date: start-date,
                end-date: end-date,
                active: true,
                total-paid: u0,
                last-payment-date: u0
            }
        )
        (var-set next-agreement-id (+ agreement-id u1))
        (ok agreement-id)
    )
)

;; Pay rent with payment tracking
(define-public (pay-rent (agreement-id uint) (amount uint))
    (let
        (
            (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
            (payment-id (var-get next-payment-id))
            (current-time (get-block-info? time u0))
        )
        (asserts! (is-eq tx-sender (get tenant agreement)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq amount (get monthly-rent agreement)) ERR-INVALID-AMOUNT)
        
        ;; Create payment record
        (map-set payments
            { agreement-id: agreement-id, payment-id: payment-id }
            {
                amount: amount,
                date: (default-to u0 current-time),
                confirmed: false,
                payer: tx-sender,
                payment-type: "rent"
            }
        )
        
        (var-set next-payment-id (+ payment-id u1))
        (ok payment-id)
    )
)

;; Confirm payment receipt
(define-public (confirm-payment (agreement-id uint) (payment-id uint))
    (let
        (
            (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
            (payment (unwrap! (map-get? payments { agreement-id: agreement-id, payment-id: payment-id }) ERR-PAYMENT-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get landlord agreement)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get confirmed payment)) ERR-PAYMENT-ALREADY-CONFIRMED)
        
        ;; Update payment status
        (map-set payments
            { agreement-id: agreement-id, payment-id: payment-id }
            (merge payment { confirmed: true })
        )
        
        ;; Update agreement payment totals
        (map-set agreements
            { agreement-id: agreement-id }
            (merge agreement 
                { 
                    total-paid: (+ (get total-paid agreement) (get amount payment)),
                    last-payment-date: (get date payment)
                }
            )
        )
        (ok true)
    )
)

;; Get payment history for agreement
(define-read-only (get-payment-history (agreement-id uint))
    (ok (map-get? payments { agreement-id: agreement-id }))
)

;; Terminate agreement
(define-public (terminate-agreement (agreement-id uint))
    (let
        (
            (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
        )
        (asserts! (or (is-eq tx-sender (get landlord agreement)) (is-eq tx-sender (get tenant agreement))) ERR-NOT-AUTHORIZED)
        (map-set agreements
            { agreement-id: agreement-id }
            (merge agreement { active: false })
        )
        (ok true)
    )
)

;; Get agreement details
(define-read-only (get-agreement-details (agreement-id uint))
    (ok (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
)

;; Check if user is landlord
(define-private (is-landlord (agreement-id uint) (user principal))
    (let
        (
            (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) false))
        )
        (is-eq user (get landlord agreement))
    )
)

;; Check if user is tenant
(define-private (is-tenant (agreement-id uint) (user principal))
    (let
        (
            (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) false))
        )
        (is-eq user (get tenant agreement))
    )
)
