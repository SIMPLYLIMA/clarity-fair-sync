;; Define constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AGREEMENT-NOT-FOUND (err u101)) 
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-PAYMENT-NOT-FOUND (err u103))
(define-constant ERR-PAYMENT-ALREADY-CONFIRMED (err u104))
(define-constant ERR-CONTRACT-PAUSED (err u105))
(define-constant ERR-INVALID-DATE (err u106))
(define-constant ERR-SECURITY-DEPOSIT-NOT-PAID (err u107))

;; Define data vars
(define-data-var next-agreement-id uint u0)
(define-data-var next-payment-id uint u0)
(define-data-var contract-paused bool false)
(define-data-var contract-owner principal tx-sender)

;; Define data maps
(define-map agreements
    { agreement-id: uint }
    {
        landlord: principal,
        tenant: principal,
        monthly-rent: uint,
        security-deposit: uint,
        security-deposit-paid: bool,
        start-date: uint,
        end-date: uint,
        active: bool,
        total-paid: uint,
        last-payment-date: uint,
        next-payment-due: uint
    }
)

(define-map payments
    { agreement-id: uint, payment-id: uint }
    {
        amount: uint,
        date: uint,
        confirmed: bool,
        payer: principal,
        payment-type: (string-utf8 20),
        is-late: bool
    }
)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
    { event-id: uint }
    {
        event-type: (string-utf8 20),
        agreement-id: uint,
        data: (optional (string-utf8 100))
    }
)

;; Contract pause/unpause functions
(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set contract-paused true)
        (ok true)
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set contract-paused false)
        (ok true)
    )
)

;; Helper function to record events
(define-private (record-event (event-type (string-utf8 20)) (agreement-id uint) (data (optional (string-utf8 100))))
    (let
        ((event-id (var-get last-event-id)))
        (map-set events
            { event-id: event-id }
            {
                event-type: event-type,
                agreement-id: agreement-id,
                data: data
            }
        )
        (var-set last-event-id (+ event-id u1))
        event-id
    )
)

;; Create new rental agreement
(define-public (create-agreement (tenant principal) (monthly-rent uint) (security-deposit uint) (start-date uint) (end-date uint))
    (let
        ((agreement-id (var-get next-agreement-id)))
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (> end-date start-date) ERR-INVALID-DATE)
        (map-set agreements
            { agreement-id: agreement-id }
            {
                landlord: tx-sender,
                tenant: tenant,
                monthly-rent: monthly-rent,
                security-deposit: security-deposit,
                security-deposit-paid: false,
                start-date: start-date,
                end-date: end-date,
                active: true,
                total-paid: u0,
                last-payment-date: u0,
                next-payment-due: start-date
            }
        )
        (var-set next-agreement-id (+ agreement-id u1))
        (record-event "agreement-created" agreement-id none)
        (ok agreement-id)
    )
)

;; Pay security deposit
(define-public (pay-security-deposit (agreement-id uint))
    (let
        ((agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND)))
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (is-eq tx-sender (get tenant agreement)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get security-deposit-paid agreement)) ERR-PAYMENT-ALREADY-CONFIRMED)
        
        (map-set agreements
            { agreement-id: agreement-id }
            (merge agreement { security-deposit-paid: true })
        )
        (record-event "security-deposit-paid" agreement-id none)
        (ok true)
    )
)

;; Pay rent with payment tracking and late payment detection
(define-public (pay-rent (agreement-id uint) (amount uint))
    (let
        (
            (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
            (payment-id (var-get next-payment-id))
            (current-time (unwrap! (get-block-info? time u0) ERR-INVALID-DATE))
            (is-late (> current-time (get next-payment-due agreement)))
        )
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (is-eq tx-sender (get tenant agreement)) ERR-NOT-AUTHORIZED)
        (asserts! (get security-deposit-paid agreement) ERR-SECURITY-DEPOSIT-NOT-PAID)
        
        (map-set payments
            { agreement-id: agreement-id, payment-id: payment-id }
            {
                amount: amount,
                date: current-time,
                confirmed: false,
                payer: tx-sender,
                payment-type: "rent",
                is-late: is-late
            }
        )
        
        (var-set next-payment-id (+ payment-id u1))
        (record-event "rent-payment-made" agreement-id none)
        (ok payment-id)
    )
)

[... remaining functions remain unchanged ...]
