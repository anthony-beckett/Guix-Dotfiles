(define-module (config systems functions wireless)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (gnu services)
  #:use-module (gnu services networking)
  #:use-module (gnu services desktop)
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
