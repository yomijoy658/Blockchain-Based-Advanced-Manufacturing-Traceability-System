;; Digital Passport Contract
;; Creates permanent product history record

(define-data-var contract-owner principal tx-sender)

;; Data structure for product digital passports
(define-map digital-passports
  { product-id: (string-ascii 64) }
  {
    product-name: (string-ascii 100),
    manufacturer: (string-ascii 100),
    manufacture-date: uint,
    components: (list 20 (string-ascii 64)),
    assembly-contract: principal,
    quality-contract: principal,
    maintenance-history: (list 10 {
      date: uint,
      service: (string-ascii 100),
      technician: (string-ascii 100)
    }),
    current-owner: principal,
    transfer-history: (list 10 {
      date: uint,
      from: principal,
      to: principal
    })
  }
)

;; Public function to create a digital passport
(define-public (create-digital-passport
    (product-id (string-ascii 64))
    (product-name (string-ascii 100))
    (manufacturer (string-ascii 100))
    (components (list 20 (string-ascii 64)))
    (assembly-contract principal)
    (quality-contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (is-none (map-get? digital-passports { product-id: product-id })) (err u101))
    (ok (map-set digital-passports
      { product-id: product-id }
      {
        product-name: product-name,
        manufacturer: manufacturer,
        manufacture-date: block-height,
        components: components,
        assembly-contract: assembly-contract,
        quality-contract: quality-contract,
        maintenance-history: (list),
        current-owner: tx-sender,
        transfer-history: (list)
      }
    ))
  )
)

;; Public function to record maintenance
(define-public (record-maintenance
    (product-id (string-ascii 64))
    (service (string-ascii 100))
    (technician (string-ascii 100)))
  (let ((passport (unwrap! (map-get? digital-passports { product-id: product-id }) (err u102))))
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))

    (ok (map-set digital-passports
      { product-id: product-id }
      (merge passport {
        maintenance-history: (unwrap!
          (as-max-len?
            (append (get maintenance-history passport)
              {
                date: block-height,
                service: service,
                technician: technician
              }
            )
            u10
          )
          (err u103)
        )
      })
    ))
  )
)

;; Public function to transfer ownership
(define-public (transfer-ownership
    (product-id (string-ascii 64))
    (new-owner principal))
  (let ((passport (unwrap! (map-get? digital-passports { product-id: product-id }) (err u102))))
    (asserts! (is-eq tx-sender (get current-owner passport)) (err u104))

    (ok (map-set digital-passports
      { product-id: product-id }
      (merge passport {
        current-owner: new-owner,
        transfer-history: (unwrap!
          (as-max-len?
            (append (get transfer-history passport)
              {
                date: block-height,
                from: tx-sender,
                to: new-owner
              }
            )
            u10
          )
          (err u103)
        )
      })
    ))
  )
)

;; Read-only function to get digital passport details
(define-read-only (get-digital-passport (product-id (string-ascii 64)))
  (map-get? digital-passports { product-id: product-id })
)

;; Initialize contract
(begin
  (var-set contract-owner tx-sender)
)
