;; Pothole Repair Tracking Contract
;; Manages reporting and repair of road surface damage

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-REPORT-NOT-FOUND (err u101))
(define-constant ERR-INVALID-INPUT (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-STATUS (err u104))

;; Data Variables
(define-data-var admin principal CONTRACT-OWNER)
(define-data-var report-counter uint u0)
(define-data-var repair-budget uint u50000)

;; Data Maps
(define-map pothole-reports
  uint
  {
    location: (string-ascii 100),
    description: (string-ascii 200),
    severity: uint,
    reporter: principal,
    reported-time: uint,
    status: (string-ascii 20),
    assigned-contractor: (optional principal),
    estimated-cost: uint,
    actual-cost: uint,
    repair-start: (optional uint),
    repair-complete: (optional uint),
    verification-required: bool
  }
)

(define-map repair-contractors
  principal
  {
    name: (string-ascii 50),
    specialization: (string-ascii 50),
    active: bool,
    total-repairs: uint,
    average-cost: uint,
    rating: uint,
    current-workload: uint
  }
)

(define-map location-history
  (string-ascii 100)
  {
    total-reports: uint,
    last-repair: uint,
    recurring-issue: bool,
    priority-boost: uint
  }
)

(define-map citizen-reporters
  principal
  {
    total-reports: uint,
    verified-reports: uint,
    reputation-score: uint,
    reward-points: uint
  }
)

;; Private Functions
(define-private (is-admin (user principal))
  (is-eq user (var-get admin))
)

(define-private (is-repair-contractor (user principal))
  (is-some (map-get? repair-contractors user))
)

(define-private (is-valid-severity (severity uint))
  (and (>= severity u1) (<= severity u5))
)

(define-private (calculate-priority (severity uint) (location (string-ascii 100)))
  (let
    (
      (location-data (default-to {total-reports: u0, last-repair: u0, recurring-issue: false, priority-boost: u0}
                                 (map-get? location-history location)))
    )
    (+ severity (get priority-boost location-data))
  )
)

(define-private (min-uint (a uint) (b uint))
  (if (<= a b) a b)
)

(define-private (max-uint (a uint) (b uint))
  (if (>= a b) a b)
)

;; Public Functions

;; Administrative Functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set admin new-admin)
    (ok true)
  )
)

(define-public (add-repair-contractor
  (contractor principal)
  (name (string-ascii 50))
  (specialization (string-ascii 50))
)
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? repair-contractors contractor)) ERR-ALREADY-EXISTS)

    (map-set repair-contractors contractor {
      name: name,
      specialization: specialization,
      active: true,
      total-repairs: u0,
      average-cost: u0,
      rating: u5,
      current-workload: u0
    })
    (ok true)
  )
)

(define-public (update-repair-budget (new-budget uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set repair-budget new-budget)
    (ok true)
  )
)

;; Citizen Reporting Functions
(define-public (report-pothole
  (location (string-ascii 100))
  (description (string-ascii 200))
  (severity uint)
)
  (let
    (
      (report-id (+ (var-get report-counter) u1))
      (reporter-data (default-to {total-reports: u0, verified-reports: u0, reputation-score: u50, reward-points: u0}
                                 (map-get? citizen-reporters tx-sender)))
    )
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-severity severity) ERR-INVALID-INPUT)

    (map-set pothole-reports report-id {
      location: location,
      description: description,
      severity: severity,
      reporter: tx-sender,
      reported-time: block-height,
      status: "reported",
      assigned-contractor: none,
      estimated-cost: u0,
      actual-cost: u0,
      repair-start: none,
      repair-complete: none,
      verification-required: (>= severity u4)
    })

    ;; Update reporter stats
    (map-set citizen-reporters tx-sender (merge reporter-data {
      total-reports: (+ (get total-reports reporter-data) u1),
      reward-points: (+ (get reward-points reporter-data) (* severity u10))
    }))

    ;; Update location history
    (let
      (
        (location-data (default-to {total-reports: u0, last-repair: u0, recurring-issue: false, priority-boost: u0}
                                   (map-get? location-history location)))
      )
      (map-set location-history location (merge location-data {
        total-reports: (+ (get total-reports location-data) u1),
        recurring-issue: (> (get total-reports location-data) u2),
        priority-boost: (if (> (get total-reports location-data) u2) u2 u0)
      }))
    )

    (var-set report-counter report-id)
    (ok report-id)
  )
)

;; Administrative Assessment Functions
(define-public (assess-report (report-id uint) (estimated-cost uint))
  (let
    (
      (report (unwrap! (map-get? pothole-reports report-id) ERR-REPORT-NOT-FOUND))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status report) "reported") ERR-INVALID-STATUS)
    (asserts! (<= estimated-cost (var-get repair-budget)) ERR-INVALID-INPUT)

    (map-set pothole-reports report-id (merge report {
      status: "assessed",
      estimated-cost: estimated-cost
    }))

    (ok true)
  )
)

(define-public (assign-repair-contractor (report-id uint) (contractor principal))
  (let
    (
      (report (unwrap! (map-get? pothole-reports report-id) ERR-REPORT-NOT-FOUND))
      (contractor-data (unwrap! (map-get? repair-contractors contractor) ERR-INVALID-INPUT))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (get active contractor-data) ERR-INVALID-INPUT)
    (asserts! (is-eq (get status report) "assessed") ERR-INVALID-STATUS)

    (map-set pothole-reports report-id (merge report {
      status: "assigned",
      assigned-contractor: (some contractor)
    }))

    ;; Update contractor workload
    (map-set repair-contractors contractor (merge contractor-data {
      current-workload: (+ (get current-workload contractor-data) u1)
    }))

    (ok true)
  )
)

;; Contractor Functions
(define-public (start-repair (report-id uint))
  (let
    (
      (report (unwrap! (map-get? pothole-reports report-id) ERR-REPORT-NOT-FOUND))
    )
    (asserts! (is-some (get assigned-contractor report)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (some tx-sender) (get assigned-contractor report)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status report) "assigned") ERR-INVALID-STATUS)

    (map-set pothole-reports report-id (merge report {
      status: "in-progress",
      repair-start: (some block-height)
    }))

    (ok true)
  )
)

(define-public (complete-repair (report-id uint) (actual-cost uint))
  (let
    (
      (report (unwrap! (map-get? pothole-reports report-id) ERR-REPORT-NOT-FOUND))
    )
    (asserts! (is-some (get assigned-contractor report)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (some tx-sender) (get assigned-contractor report)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status report) "in-progress") ERR-INVALID-STATUS)
    (asserts! (<= actual-cost (* (get estimated-cost report) u2)) ERR-INVALID-INPUT)

    (map-set pothole-reports report-id (merge report {
      status: (if (get verification-required report) "pending-verification" "completed"),
      repair-complete: (some block-height),
      actual-cost: actual-cost
    }))

    ;; Update contractor stats
    (match (get assigned-contractor report)
      contractor-principal (match (map-get? repair-contractors contractor-principal)
        contractor-data (map-set repair-contractors contractor-principal (merge contractor-data {
          current-workload: (- (get current-workload contractor-data) u1),
          total-repairs: (+ (get total-repairs contractor-data) u1),
          average-cost: (/ (+ (* (get average-cost contractor-data) (get total-repairs contractor-data)) actual-cost)
                          (+ (get total-repairs contractor-data) u1))
        }))
        false
      )
      false
    )

    ;; Update location history
    (map-set location-history (get location report) {
      total-reports: u0,
      last-repair: block-height,
      recurring-issue: false,
      priority-boost: u0
    })

    (ok true)
  )
)

(define-public (verify-repair (report-id uint) (approved bool))
  (let
    (
      (report (unwrap! (map-get? pothole-reports report-id) ERR-REPORT-NOT-FOUND))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status report) "pending-verification") ERR-INVALID-STATUS)

    (map-set pothole-reports report-id (merge report {
      status: (if approved "completed" "rejected")
    }))

    ;; Update reporter reputation if approved
    (if approved
      (match (map-get? citizen-reporters (get reporter report))
        reporter-data (map-set citizen-reporters (get reporter report) (merge reporter-data {
          verified-reports: (+ (get verified-reports reporter-data) u1),
          reputation-score: (min-uint (+ (get reputation-score reporter-data) u5) u100),
          reward-points: (+ (get reward-points reporter-data) u50)
        }))
        false
      )
      false
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-pothole-report (report-id uint))
  (map-get? pothole-reports report-id)
)

(define-read-only (get-repair-contractor (contractor principal))
  (map-get? repair-contractors contractor)
)

(define-read-only (get-location-history (location (string-ascii 100)))
  (map-get? location-history location)
)

(define-read-only (get-citizen-reporter (reporter principal))
  (map-get? citizen-reporters reporter)
)

(define-read-only (get-repair-budget)
  (var-get repair-budget)
)

(define-read-only (get-report-counter)
  (var-get report-counter)
)
