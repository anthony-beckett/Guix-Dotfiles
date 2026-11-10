(define-module (system services functions wireless)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (gnu services)
  #:use-module (gnu services bluetooth)
  #:use-module (gnu services networking)
  #:export (wireless)
  )

(define (wireless os)
  (operating-system
   (inherit os)

   (services
    (cons*
     (service bluetooth-service-type)
     (service network-manager-service-type)
     %base-services))))
