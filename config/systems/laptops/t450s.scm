(define-module (config systems laptops t450s)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages video)
  #:use-module (config systems laptop-system))

(operating-system
 (inherit laptop-system)
 (host-name "lunanova")
 (kernel linux)
 (firmware (list
	        linux-firmware
	        i915-firmware
	        intel-microcode))
 (timezone "Australia/Adelaide")
 (locale "en_AU.utf8")
 (keyboard-layout (keyboard-layout "us"))

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

 (bootloader (bootloader-configuration
              (bootloader grub-bootloader)
              (targets '("/dev/vda"))
              (terminal-outputs '(console))))

 (packages (cons*
            emacs
            %base-packages
            ))

 (file-systems (cons
                (file-system
                 (mount-point "/tmp")
                 (device "none")
                 (type "tmpfs")
                 (check? #f))
                %base-file-systems))
 )
