(define-module (config systems laptop-system)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (config systems base-system-skelington)
  #:export (laptop-system))

(use-package-modules emacs)
(use-service-modules desktop pm)

(define laptop-system
  (operating-system
   (inherit base-system)
   (host-name "laptop-system")
   (timezone "Australia/Adelaide")
   (locale "en_AU.utf8")
   (keyboard-layout (keyboard-layout "us"))

   ;; Don't include any default firmware
   (firmware '())

   ;; The bootloader and file-systems fields here will be replaced by
   ;; the exact same values in the gemini and taurus configurations,
   ;; but in practice these fields will depend on each machine's
   ;; partition configuration.
   (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets '("/dev/vda"))
                (terminal-outputs '(console))))

   (file-systems (cons
                  (file-system
                   (mount-point "/tmp")
                   (device "none")
                   (type "tmpfs")
                   (check? #f))
                  %base-file-systems))

   (users (cons (user-account
                 (name "ajbeckett")
                 (comment "Anthony J. Beckett")
                 (group "users")
                 (supplementary-groups '(
                                         "audio"
                                         "input"
                                         "netdev"
                                         "video"
                                         "wheel"
                                         "lp"
                                         )))
                %base-user-accounts))

   (services (cons*
              (service tlp-service-type
                       (tlp-configuration
                        (cpu-scaling-governor-on-ac '("performance"))
                        (cpu-scaling-governor-on-bat '("powersave"))
                        (sched-powersave-on-bat? #t)))
              (service bluetooth-service-type
                       (bluetooth-configuration
                        (auto-enable? #t)))
              %desktop-services))))
