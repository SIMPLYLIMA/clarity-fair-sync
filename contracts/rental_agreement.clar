;; Define constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AGREEMENT-NOT-FOUND (err u101)) 
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-PAYMENT-NOT-FOUND (err u103))
(define-constant ERR-PAYMENT-ALREADY-CONFIRMED (err u104))
(define-constant ERR-CONTRACT-PAUSED (err u105))
(define-constant ERR-INVALID-DATE (err u106))
(define-constant ERR-SECURITY-DEPOSIT-NOT-PAID (err u107))
(define-constant ERR-PAYMENT-TOO-SMALL (err u108))
(define-constant ERR-GRACE-PERIOD-EXPIRED (err u109))

;; Define data vars
(define-data-var next-agreement-id uint u0)
(define-data-var next-payment-id uint u0)
(define-data-var contract-paused bool false)
(define-data-var contract-owner principal tx-sender)
(define-data-var grace-period-days uint u5)

;; Enhanced agreements map
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
        next-payment-due: uint,
        grace-period-end: uint
    }
)

;; Enhanced payments map
(define-map payments
    { agreement-id: uint, payment-id: uint }
    {
        amount: uint,
        date: uint,
        confirmed: bool,
        payer: principal,
        payment-type: (string-utf8 20),
        is-late: bool,
        remaining-balance: uint
    }
)

;; Enhanced events
(define-data-var last-event-id uint u0)

(define-map events
    { event-id: uint }
    {
        event-type: (string-utf8 20),
        agreement-id: uint,
        data: (optional (string-utf8 100)),
        timestamp: uint
    }
)

;; Helper function for payment validation
(define-private (is-valid-payment (agreement-id uint) (amount uint))
    (let
        ((agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) false)))
        (and
            (>= amount u0)
            (<= amount (get monthly-rent agreement))
            (get active agreement)
        )
    )
)

;; Enhanced record-event function
(define-private (record-event (event-type (string-utf8 20)) (agreement-id uint) (data (optional (string-utf8 100))))
    (let
        (
            (event-id (var-get last-event-id))
            (current-time (unwrap! (get-block-info? time u0) u0))
        )
        (map-set events
            { event-id: event-id }
            {
                event-type: event-type,
                agreement-id: agreement-id,
                data: data,
                timestamp: current-time
            }
        )
        (var-set last-event-id (+ event-id u1))
        event-id
    )
)

;; Enhanced pay-rent function with validation
(define-public (pay-rent (agreement-id uint) (amount uint))
    (let
        (
            (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND))
            (payment-id (var-get next-payment-id))
            (current-time (unwrap! (get-block-info? time u0) ERR-INVALID-DATE))
            (is-late (> current-time (get next-payment-due agreement)))
            (grace-period-end (get grace-period-end agreement))
        )
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (is-eq tx-sender (get tenant agreement)) ERR-NOT-AUTHORIZED)
        (asserts! (get security-deposit-paid agreement) ERR-SECURITY-DEPOSIT-NOT-PAID)
        (asserts! (is-valid-payment agreement-id amount) ERR-INVALID-AMOUNT)
        (asserts! (or (not is-late) (<= current-time grace-period-end)) ERR-GRACE-PERIOD-EXPIRED)
        
        (map-set payments
            { agreement-id: agreement-id, payment-id: payment-id }
            {
                amount: amount,
                date: current-time,
                confirmed: false,
                payer: tx-sender,
                payment-type: "rent",
                is-late: is-late,
                remaining-balance: (- (get monthly-rent agreement) amount)
            }
        )
        
        (var-set next-payment-id (+ payment-id u1))
        (record-event "rent-payment-made" 
                    agreement-id 
                    (some (concat (concat "Amount: " (to-string amount)) 
                                (concat " Late: " (to-string is-late)))))
        (ok payment-id)
    )
)

[... remaining functions unchanged ...]
