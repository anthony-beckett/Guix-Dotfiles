(define-module (config systems functions laptop)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (gnu services desktop)
  #:use-module (gnu services pm)
  #:use-module (gnu packages linux)
  #:export (laptop)
  )

(define (laptop os)
  (operating-system
   (inherit os)

   (packages
    (append
     (list
      brightnessctl
      acpi)
     %base-packages))

   (services
    (cons*
     (service tlp-service-type
              (tlp-configuration
               (tlp-default-mode "BAT")
               (cpu-scaling-governor-on-ac '("performance"))
               (energy-perf-policy-on-bat "power")
               (sched-powersave-on-bat? #t)
               (pcie-aspm-on-bat "powersave")
               (wifi-pwr-on-bat? #t)
               (runtime-pm-on-bat "auto")))

     (service elogind-service-type
              (elogind-configuration
               (handle-lid-switch 'suspend)
               (handle-lid-switch-external-power 'suspend)
               (handle-lid-switch-docked 'ignore)))

     %desktop-services))))
