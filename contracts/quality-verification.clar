;; Quality Verification Contract
;; Records testing and inspection results

(define-data-var contract-owner principal tx-sender)

;; Data structure for quality checks
(define-map quality-checks
  { product-id: (string-ascii 64), check-id: uint }
  {
    check-name: (string-ascii 100),
    check-type: (string-ascii 50),
    result: (string-ascii 100),
    pass-fail: bool,
    inspector: principal,
    timestamp: uint,
    notes: (string-ascii 256)
  }
)

;; Data structure for product quality summary
(define-map product-quality
  { product-id: (string-ascii 64) }
  {
    total-checks: uint,
    passed-checks: uint,
    final-approval: bool,
    approval-date: uint,
    approver: principal
  }
)

;; Public function to initialize quality tracking for a product
(define-public (initialize-quality-tracking (product-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (is-none (map-get? product-quality { product-id: product-id })) (err u101))
    (ok (map-set product-quality
      { product-id: product-id }
      {
        total-checks: u0,
        passed-checks: u0,
        final-approval: false,
        approval-date: u0,
        approver: tx-sender
      }
    ))
  )
)

;; Public function to record a quality check
(define-public (record-quality-check
    (product-id (string-ascii 64))
    (check-name (string-ascii 100))
    (check-type (string-ascii 50))
    (result (string-ascii 100))
    (pass-fail bool)
    (notes (string-ascii 256)))
  (let (
    (quality-summary (unwrap! (map-get? product-quality { product-id: product-id }) (err u102)))
    (next-check (+ (get total-checks quality-summary) u1))
    (new-passed-checks (if pass-fail (+ (get passed-checks quality-summary) u1) (get passed-checks quality-summary)))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))

    ;; Record the quality check
    (map-set quality-checks
      { product-id: product-id, check-id: next-check }
      {
        check-name: check-name,
        check-type: check-type,
        result: result,
        pass-fail: pass-fail,
        inspector: tx-sender,
        timestamp: block-height,
        notes: notes
      }
    )

    ;; Update the product quality summary
    (ok (map-set product-quality
      { product-id: product-id }
      (merge quality-summary {
        total-checks: next-check,
        passed-checks: new-passed-checks
      })
    ))
  )
)

;; Public function to give final quality approval
(define-public (approve-product-quality (product-id (string-ascii 64)))
  (let ((quality-summary (unwrap! (map-get? product-quality { product-id: product-id }) (err u102))))
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (not (get final-approval quality-summary)) (err u103))
    (ok (map-set product-quality
      { product-id: product-id }
      (merge quality-summary {
        final-approval: true,
        approval-date: block-height,
        approver: tx-sender
      })
    ))
  )
)

;; Read-only function to get quality check details
(define-read-only (get-quality-check (product-id (string-ascii 64)) (check-id uint))
  (map-get? quality-checks { product-id: product-id, check-id: check-id })
)

;; Read-only function to get product quality summary
(define-read-only (get-product-quality (product-id (string-ascii 64)))
  (map-get? product-quality { product-id: product-id })
)

;; Initialize contract
(begin
  (var-set contract-owner tx-sender)
)
