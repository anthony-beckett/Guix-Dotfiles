(define-module (config systems lunanova)
  #:use-modules (gnu)
  #:use-modules (gnu system)
  #:use-modules (gnu packages linux)
  #:use-modules (gnu packages video)
  #:use-modules (nongnu packages linux)
  #:use-modules (nongnu packages video)
  #:use-modules (config systems laptop-system))

(operating-system
 (inherit laptop-os)
 (host-name "lunanova")
 (firmware (list
	        linux-firmware
	        i915-firmware
	        intel-microcode))

 (packages (cons*
            intel-media-driver-nonfree
            libva-utils
            %base-packages))

 (file-systems
  (cons* (file-system (mount-point "/boot/efi")
		              (device (uuid "FCE6-96C0"
				                    'fat32))
		              (type "vfat"))
	     (file-system (mount-point "/")
		              (device (uuid
			                   "5c890181-055c-4db3-9a47-2e3769ec24ea"
			                   'ext4))
		              (type "ext4"))
	     %base-file-systems))
 (swap-devices (list (swap-space
		              (target (uuid
				               "5abe7967-fcb6-4888-8b05-a6413944c60b"))))))
