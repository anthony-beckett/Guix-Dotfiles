(define-module (config systems t450s)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages video)
  #:use-module (config systems functions laptop)
  #:use-module (config systems functions desktop)
  #:use-module (config systems functions wireless)
  )

(define %cryptroot
  (mapped-device
   (source (uuid "6464dd7f-e62d-4fed-9f77-80908e792c54"))
   (target "cryptroot")
   (type luks-device-mapping)
   (arguments '(#:allow-discards? #t))))

(define %crypthome
  (mapped-device
   (source (uuid "49e3241d-24bd-4d05-9df5-e36276d9a6f6"))
   (target "crypthome")
   (type luks-device-mapping)
   (arguments '(#:key-file "/keys/home.key"
                #:allow-discards? #t))))

;; TEMPORARY: Place in own functions later
(define %my-services
  (modify-services %desktop-services
		           (guix-service-type config =>
				                      (guix-configuration
					                   (inherit config)
					                   (substitute-urls
					                    (append
					                     (list
					                      "https://substitutes.nonguix.org"
					                      "https://guix.bordeaux.inria.fr")
					                     %default-substitute-urls))
					                   (authorized-keys
					                    (append
					                     (list
					                      (plain-file
						                   "non-guix.pub"
						                   "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))")
					                      (plain-file
						                   "bordeaux.inria.pub"
						                   "(public-key (ecc (curve Ed25519) (q #89FBA276A976A8DE2A69774771A92C8C879E0F24614AAAAE23119608707B3F06#)))"))
					                     %default-authorized-guix-keys))))))


(define lunanova (operating-system
                  (inherit laptop-system)
                  (host-name "lunanova")
                  (kernel linux)
                  (firmware (list
	                         linux-firmware
	                         i915-firmware
	                         intel-microcode))
                  (initrd microcode-initrd)
                  (initrd-modules
                   (append
                    (list
	                 "aesni_intel"
	                 "cryptd"
	                 "gf128mul"
	                 "xts"
	                 "i915"
	                 ) %base-initrd-modules))
                  (firmware (cons* sof-firmware linux-firmware %base-firmware))
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
                                                        "kvm"
                                                        "lp"
                                                        "netdev"
                                                        "video"
                                                        "wheel"
                                                        )))
                               %base-user-accounts))

                  (bootloader (bootloader-configuration
                               (bootloader grub-bootloader)
                               (targets '("/dev/vda"))
                               (terminal-outputs '(console))))

                  (services
                   (cons*
                    (service gnome-keyring-service-type)
                    (service mate-desktop-service-type)
                    %my-services))

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
                  (bootloader (bootloader-configuration
		                       (bootloader grub-efi-bootloader)
		                       (targets (list "/boot/efi"))
		                       (keyboard-layout keyboard-layout)))

                  (mapped-devices (list %cryptroot %crypthome))


                  (kernel-arguments
                   (append (list "resume=/dev/mapper/cryptroot"
		                         "resume_offset=13498931")
	                       %default-kernel-arguments))

                  ;; The list of file systems that get "mounted".  The unique
                  ;; file system identifiers there ("UUIDs") can be obtained
                  ;; by running 'blkid' in a terminal.
                  (file-systems (cons* (file-system
			                            (mount-point "/")
			                            (device "/dev/mapper/cryptroot")
			                            (type "btrfs")
			                            (flags '(no-atime))
			                            (options "compress,ssd_spread,discard=async")
			                            (dependencies (list %cryptroot)))

		                               (file-system
			                            (device "/dev/mapper/cryptroot")
			                            (mount-point "/swap")
			                            (type "btrfs")
			                            (options "subvol=swap,nodatacow,ssd")
			                            (dependencies (list %cryptroot)))

		                               (file-system
			                            (mount-point "/boot/efi")
			                            (device (uuid "86A8-D792" 'fat32))
			                            (type "vfat"))

		                               (file-system
			                            (mount-point "/home")
			                            (device "/dev/mapper/crypthome")
			                            (type "ext4")
			                            (flags '(no-atime))
			                            (options "commit=60,errors=remount-ro")
			                            (dependencies (list %crypthome)))
		                               %base-file-systems))

                  (swap-devices
                   (list
                    (swap-space
	                 (target "/swap/swapfile")
	                 (priority 10)
	                 (dependencies (list %cryptroot)))))
                  ))

(wireless
 (laptop
  (desktop lunanova)))
