(define-module (config systems functions desktop)
  #:use-module (gnu)
  #:use-module (guix)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (gnu services cups)
  #:use-module (gnu services desktop)
  #:use-module (gnu services networking)
  #:export (desktop)
  )

(define (desktop os)
  (operating-system
   (inherit os)

   (packages
    (append
     (list
      "avahi"
      "brightnessctl"
      "ffmpeg"
      "gvfs"
      "mesa-utils"
      "nss-certs"
      "pavucontrol"
      "playerctl"
      "wl-clipboard"
      "xclip"
      "xdg-utils"
      )
     %base-packages))

   (services
    (cons*
     (service guix-publish-service-type
	          (guix-publish-configuration
		       (host "0.0.0.0")
		       (port 7777)
		       (advertise? #t)))
     (service accountsservice-service-type)
     (service avahi-service-type)
     (service cups-service-type)
     (service dbus-service-type)
     (service elogind-service-type)
     (service fstrim-service-type)
     (service ipfs-service-type)
     (service nscd-service-type)
     (service ntp-service-type
              (ntp-configuration))
     (service openssh-service-type)
     (service pipewire-service-type)
     (service polkit-service-type)
     (service udev-service-type)
     %desktop-services))))
