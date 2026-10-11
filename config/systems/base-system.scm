(define-module (config systems base-system)
  #:use-module (srfi srfi-1)
  #:use-module (gnu)
  #:use-module (gnu packages android)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages certs)
  #:use-module (gnu packages containers)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages file-systems)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages nfs)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages wm)
  #:use-module (gnu services admin)
  #:use-module (gnu services audio)
  #:use-module (gnu services avahi)
  #:use-module (gnu services containers)
  #:use-module (gnu services cups)
  #:use-module (gnu services dbus)
  #:use-module (gnu services desktop)
  #:use-module (gnu services dns)
  #:use-module (gnu services guix)
  #:use-module (gnu services linux)
  #:use-module (gnu services mcron)
  #:use-module (gnu services networking)
  #:use-module (gnu services nix)
  #:use-module (gnu services pm)
  #:use-module (gnu services ssh)
  #:use-module (gnu services virtualization)
  #:use-module (gnu services xorg)
  #:use-module (gnu system)
  #:use-module (gnu system accounts)
  #:use-module (gnu system nss)
  #:use-module (gnu system privilege)
  #:use-module (gnu system setuid)
  #:use-module (gnu system shadow)
  #:use-module (guix)
  #:use-module (guix gexp)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages video)
  #:use-module (nongnu system linux-initrd)
  #:export (base-operating-system
            guix-home-config))

(define %iptables-ipv4-rules
  (plain-file "iptables.rules" "*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp --dport 22000 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-port-unreachable
COMMIT
"))

(define-public base-operating-system
  (operating-system
   (host-name "cyberia")
   (timezone "Australia/Adelaide")
   (locale "en_AU.utf8")

   ;; Use non-free Linux and firmware
   (kernel linux)
   (firmware (list linux-firmware))
   (initrd microcode-initrd)

   ;; Additional kernel modules
   (kernel-loadable-modules (list v4l2loopback-linux-module))

   ;; Choose US English keyboard layout.
   (keyboard-layout (keyboard-layout "us"))

   ;; Use the UEFI variant of GRUB with the EFI System
   ;; Partition mounted on /boot/efi.
   (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))
                (keyboard-layout keyboard-layout)))

   ;; Guix doesn't like it when there isn't a file-systems
   ;; entry, so add one that is meant to be overridden
   (file-systems (cons*
                  (file-system
                   (mount-point "/tmp")
                   (device "none")
                   (type "tmpfs")
                   (check? #f))
                  %base-file-systems))

   (users (cons (user-account
                 (name "ajbeckett")
                 (comment "Anthony Beckett")
                 (group "users")
                 (home-directory "/home/ajbeckett")
                 (supplementary-groups '("wheel"  ;; sudo
                                         "adbusers"
                                         "netdev" ;; network devices
                                         "kvm"
                                         "tty"
                                         "input"
                                         "cgroup"
                                         "lp"       ;; control bluetooth devices
                                         "audio"    ;; control audio devices
                                         "video"))) ;; control video devices

                %base-user-accounts))

   ;; Install bare-minimum system packages
   (packages (cons* bluez
                    bluez-alsa
                    brightnessctl
                    buildah          ;; for building images
                    exfat-utils
                    fuse-exfat
                    git
                    gvfs             ;; Enable user mounts
                    ;;intel-media-driver/nonfree
                    libva-utils
                    neovim
                    ntfs-3g
                    podman           ;; container runtime
                    podman-compose   ;; for docker-compose compatibility
                    stow
                    %base-packages))

   ;; Configure only the services necessary to run the system
   (services (append
              (modify-services %base-services
                               (delete login-service-type)
                               (delete mingetty-service-type)
                               (delete console-font-service-type))
              (list
               ;; Seat management (can't use seatd because Wireplumber depends on elogind)
               (service elogind-service-type)

               ;; Configure TTYs and graphical greeter
               (service console-font-service-type
                        (map (lambda (tty)
                               ;; Use a larger font for HIDPI screens
                               (cons tty (file-append
                                          font-terminus
                                          "/share/consolefonts/ter-132n")))
                             '("tty1" "tty2" "tty3")))

               (service greetd-service-type
                        (greetd-configuration
                         (greeter-supplementary-groups (list "video" "input"))
                         (terminals
                          (list
                           ;; TTY1 is the graphical login screen for Sway
                           (greetd-terminal-configuration
                            (terminal-vt "1")
                            (terminal-switch #t)
                            )

                           ;; Set up remaining TTYs for terminal use
                           (greetd-terminal-configuration (terminal-vt "2"))
                           (greetd-terminal-configuration (terminal-vt "3"))))))

               ;; Configure swaylock as a setuid program
               ;;               (service screen-locker-service-type
               ;;                        (screen-locker-configuration
               ;;                         (name "swaylock")
               ;;                         (program (file-append swaylock "/bin/swaylock"))
               ;;                         (using-pam? #t)
               ;;                         (using-setuid? #f)))

               ;; Configure the Guix service and ensure we use Nonguix substitutes
               (simple-service 'add-nonguix-substitutes
                               guix-service-type
                               (guix-extension
                                (substitute-urls
                                 (cons* "https://nonguix-proxy.ditigal.xyz"
                                        %default-substitute-urls))
                                (authorized-keys
                                 (append (list (plain-file "nonguix.pub"
                                                           "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))
                                         %default-authorized-guix-keys))))

               ;; Set up Polkit to allow `wheel' users to run admin tasks
               polkit-wheel-service

               ;; Give certain programs super-user access
               (simple-service 'mount-setuid-helpers
                               privileged-program-service-type
                               (map (lambda (program)
                                      (privileged-program
                                       (program program)
                                       (setuid? #t)))
                                    (list (file-append nfs-utils "/sbin/mount.nfs")
                                          (file-append ntfs-3g "/sbin/mount.ntfs-3g"))))

               ;; Networking services
               (service network-manager-service-type
                        (network-manager-configuration
                         (vpn-plugins
                          (list network-manager-openvpn))))
               (service wpa-supplicant-service-type) ;; Needed by NetworkManager
               (service modem-manager-service-type)  ;; For cellular modems
               (service bluetooth-service-type
                        (bluetooth-configuration
                         (auto-enable? #t)))
               (service usb-modeswitch-service-type)

               (service iptables-service-type
                        (iptables-configuration
                         (ipv4-rules %iptables-ipv4-rules)))

               ;; Add extra hosts for local testing of web projects
               ;;(simple-service 'dev-hosts
               ;;                hosts-service-type
               ;;                (list (host "127.0.0.1"
               ;;                            "localhost"
               ;;                            (list "systemcrafters.local"
               ;;                                  "ci.systemcrafters.local"))
               ;;                      ;; Route Enclave chat over the WireGuard
               ;;                      ;; tunnel to avoid the ISP CGNAT path.
               ;;                      ;; Never pin bare 0x11.run here: it's the
               ;;                      ;; WG endpoint hostname (services/vpn.scm)
               ;;                      ;; and pinning it would loop the tunnel.
               ;;                      (host "10.11.0.1" "chat.0x11.run")))

               ;; Basic desktop system services (copied from %desktop-services)
               (service avahi-service-type)
               (service udisks-service-type)
               (service upower-service-type)
               (service cups-pk-helper-service-type)
               (service geoclue-service-type)
               (service polkit-service-type)
               (service dbus-root-service-type)
               fontconfig-file-system-service ;; Manage the fontconfig cache

               ;; Power and thermal management services
               (service thermald-service-type)
               (service tlp-service-type
                        (tlp-configuration
                         (cpu-boost-on-ac? #t)
                         (wifi-pwr-on-bat? #t)))

               ;; Configure v4l2loopback module for virtual cameras
               ;; See also: https://stackoverflow.com/a/66072635
               ;;           https://github.com/umlaeute/v4l2loopback
               (service kernel-module-loader-service-type '("v4l2loopback"))
               (simple-service 'v4l2loopback-config etc-service-type
                               (list `("modprobe.d/v4l2loopback.conf"
                                       ,(plain-file "v4l2loopback.conf"
                                                    "options v4l2loopback devices=1 video_nr=2 exclusive_caps=1 card_label=\"OBS Virtual Camera\""))))


               ;; Enable Docker containers and virtual machines
               ;;(service containerd-service-type)
               ;;(service docker-service-type)
               (service libvirt-service-type
                        (libvirt-configuration
                         (unix-sock-group "libvirt")
                         (tls-port "16555")))

               (service rootless-podman-service-type
                        (rootless-podman-configuration
                         (subgids
                          (list (subid-range (name "ajbeckett"))))
                         (subuids
                          (list (subid-range (name "ajbeckett"))))))

               ;; Enable SSH access
               (service openssh-service-type
                        (openssh-configuration
                         (openssh openssh-sans-x)
                         (port-number 2222)))

               ;; Enable printing and scanning
               (service sane-service-type)
               (service cups-service-type
                        (cups-configuration
                         (web-interface? #t)
                         (extensions
                          (list cups-filters))))

               ;; Set up the X11 socket directory for XWayland
               (service x11-socket-directory-service-type)

               ;; Sync system clock with time servers
               (service ntp-service-type)

               ;; Add udev rules for MTP (mobile) devices for non-root user access
               (simple-service 'mtp udev-service-type (list libmtp))
               (udev-rules-service 'android android-udev-rules
                                   #:groups '("adbusers"))

               ;; Add udev rules for a few packages
               (udev-rules-service 'pipewire-add-udev-rules pipewire)
               (udev-rules-service 'brightnessctl-udev-rules brightnessctl)

               ;; Enable the build service for Nix package manager
               (service nix-service-type)

               ;; Schedule cron jobs for system tasks
               (simple-service 'system-cron-jobs
                               mcron-service-type
                               (list
                                ;; Run `guix gc' 5 minutes after midnight every day.
                                ;; Clean up generations older than 2 months and free
                                ;; at least 10G of space.
                                #~(job "5 0 * * *" "guix gc -d 2m -F 10G"))))))

   ;; Allow resolution of '.local' host names with mDNS
   (name-service-switch %mdns-host-lookup-nss)))

(define (guix-home-config home-environment)
  "Helper function to create a guix-home service for user 'ajbeckett'."
  (service guix-home-service-type
           `(("ajbeckett" ,home-environment))))
