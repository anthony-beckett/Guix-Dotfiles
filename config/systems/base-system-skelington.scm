(define-module (config systems base-system-skelington)
  #:use-module (gnu)
  #:use-module (guix)
  #:export (base-system))

(use-package-modules ssh)
(use-service-modules networking ssh)

(define base-system
  (operating-system
   (host-name "base-system")
   (timezone "Australia/Adelaide")
   (locale "en_AU.utf8")
   (keyboard-layout (keyboard-layout "us"))

   ;; Don't include any default firmware
   (firmware '())

   (initrd (lambda (file-systems . rest)
             ;; Create a standard initrd but set up networking
             ;; with the parameters QEMU expects by default.
             (apply base-initrd file-systems
                    #:qemu-networking? #t
                    rest)))

   ;; The bootloader and file-systems fields here will be replaced by
   ;; actual instantiations according to each machine
   (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets '("/dev/vda"))
                (terminal-outputs '(console))))

   (file-systems (cons*
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
                                         )))
                %base-user-accounts))

   (services (cons* (service dhcp-client-service-type)
                    (service openssh-service-type)
                    %base-services))

   ;; Allow resolution of '.local' host names with mDNS.
   (name-service-switch %mdns-host-lookup-nss)
   ))
