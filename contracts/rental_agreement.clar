;; Define constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AGREEMENT-NOT-FOUND (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))

;; Define data vars
(define-data-var next-agreement-id uint u0)

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
        active: bool
    }
)

(define-map payments
    { agreement-id: uint, payment-id: uint }
    {
        amount: uint,
        date: uint,
        confirmed: bool
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
                active: true
            }
        )
        (var-set next-agreement-id (+ agreement-id u1))
        (ok agreement-id)
    )
)

;; Pay rent
(define-public (pay-rent (agreement-id uint) (amount uint))
    (let
        (
            (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get tenant agreement)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq amount (get monthly-rent agreement)) ERR-INVALID-AMOUNT)
        (ok true)
    )
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