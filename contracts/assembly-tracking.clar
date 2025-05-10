;; Assembly Tracking Contract
;; Monitors production process steps

(define-data-var contract-owner principal tx-sender)

;; Data structure for assembly steps
(define-map assembly-steps
  { product-id: (string-ascii 64), step-id: uint }
  {
    step-name: (string-ascii 100),
    materials-used: (list 10 (string-ascii 64)),
    timestamp: uint,
    operator: principal,
    status: (string-ascii 20),
    notes: (string-ascii 256)
  }
)

;; Data structure for product assembly history
(define-map product-assembly
  { product-id: (string-ascii 64) }
  {
    total-steps: uint,
    start-time: uint,
    completion-time: uint,
    is-completed: bool
  }
)

;; Public function to initialize a new product assembly
(define-public (initialize-assembly (product-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (is-none (map-get? product-assembly { product-id: product-id })) (err u101))
    (ok (map-set product-assembly
      { product-id: product-id }
      {
        total-steps: u0,
        start-time: block-height,
        completion-time: u0,
        is-completed: false
      }
    ))
  )
)

;; Public function to record an assembly step
(define-public (record-assembly-step
    (product-id (string-ascii 64))
    (step-name (string-ascii 100))
    (materials-used (list 10 (string-ascii 64)))
    (status (string-ascii 20))
    (notes (string-ascii 256)))
  (let (
    (product (unwrap! (map-get? product-assembly { product-id: product-id }) (err u102)))
    (next-step (+ (get total-steps product) u1))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (not (get is-completed product)) (err u103))

    ;; Record the assembly step
    (map-set assembly-steps
      { product-id: product-id, step-id: next-step }
      {
        step-name: step-name,
        materials-used: materials-used,
        timestamp: block-height,
        operator: tx-sender,
        status: status,
        notes: notes
      }
    )

    ;; Update the product assembly record
    (ok (map-set product-assembly
      { product-id: product-id }
      (merge product { total-steps: next-step })
    ))
  )
)

;; Public function to complete assembly
(define-public (complete-assembly (product-id (string-ascii 64)))
  (let ((product (unwrap! (map-get? product-assembly { product-id: product-id }) (err u102))))
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (not (get is-completed product)) (err u103))
    (ok (map-set product-assembly
      { product-id: product-id }
      (merge product {
        completion-time: block-height,
        is-completed: true
      })
    ))
  )
)

;; Read-only function to get assembly step details
(define-read-only (get-assembly-step (product-id (string-ascii 64)) (step-id uint))
  (map-get? assembly-steps { product-id: product-id, step-id: step-id })
)

;; Read-only function to get product assembly details
(define-read-only (get-product-assembly (product-id (string-ascii 64)))
  (map-get? product-assembly { product-id: product-id })
)

;; Initialize contract
(begin
  (var-set contract-owner tx-sender)
)
