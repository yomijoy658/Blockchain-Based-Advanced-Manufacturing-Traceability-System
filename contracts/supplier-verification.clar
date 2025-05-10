;; Supplier Verification Contract
;; Validates parts manufacturers and their credentials

(define-data-var contract-owner principal tx-sender)

;; Data structure for supplier information
(define-map suppliers
  { supplier-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    address: (string-ascii 256),
    certification-date: uint,
    is-verified: bool,
    verification-authority: principal
  }
)

;; Public function to register a new supplier
(define-public (register-supplier
    (supplier-id (string-ascii 64))
    (name (string-ascii 100))
    (address (string-ascii 256))
    (certification-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (is-none (map-get? suppliers { supplier-id: supplier-id })) (err u101))
    (ok (map-set suppliers
      { supplier-id: supplier-id }
      {
        name: name,
        address: address,
        certification-date: certification-date,
        is-verified: false,
        verification-authority: tx-sender
      }
    ))
  )
)

;; Public function to verify a supplier
(define-public (verify-supplier (supplier-id (string-ascii 64)))
  (let ((supplier (unwrap! (map-get? suppliers { supplier-id: supplier-id }) (err u102))))
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (ok (map-set suppliers
      { supplier-id: supplier-id }
      (merge supplier { is-verified: true, verification-authority: tx-sender })
    ))
  )
)

;; Read-only function to check if a supplier is verified
(define-read-only (is-supplier-verified (supplier-id (string-ascii 64)))
  (match (map-get? suppliers { supplier-id: supplier-id })
    supplier (ok (get is-verified supplier))
    (err u102)
  )
)

;; Read-only function to get supplier details
(define-read-only (get-supplier-details (supplier-id (string-ascii 64)))
  (map-get? suppliers { supplier-id: supplier-id })
)

;; Initialize contract
(begin
  (var-set contract-owner tx-sender)
)
