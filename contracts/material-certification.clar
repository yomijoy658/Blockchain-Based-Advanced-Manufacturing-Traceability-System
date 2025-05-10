;; Material Certification Contract
;; Records specifications and testing of materials

(define-data-var contract-owner principal tx-sender)

;; Data structure for material certifications
(define-map material-certifications
  { material-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    supplier-id: (string-ascii 64),
    specifications: (string-ascii 256),
    test-results: (string-ascii 256),
    certification-date: uint,
    certifier: principal
  }
)

;; Public function to register a new material certification
(define-public (register-material
    (material-id (string-ascii 64))
    (name (string-ascii 100))
    (supplier-id (string-ascii 64))
    (specifications (string-ascii 256))
    (test-results (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (is-none (map-get? material-certifications { material-id: material-id })) (err u101))
    (ok (map-set material-certifications
      { material-id: material-id }
      {
        name: name,
        supplier-id: supplier-id,
        specifications: specifications,
        test-results: test-results,
        certification-date: block-height,
        certifier: tx-sender
      }
    ))
  )
)

;; Public function to update test results
(define-public (update-test-results
    (material-id (string-ascii 64))
    (new-test-results (string-ascii 256)))
  (let ((material (unwrap! (map-get? material-certifications { material-id: material-id }) (err u102))))
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (ok (map-set material-certifications
      { material-id: material-id }
      (merge material {
        test-results: new-test-results,
        certification-date: block-height
      })
    ))
  )
)

;; Read-only function to get material certification details
(define-read-only (get-material-details (material-id (string-ascii 64)))
  (map-get? material-certifications { material-id: material-id })
)

;; Initialize contract
(begin
  (var-set contract-owner tx-sender)
)
