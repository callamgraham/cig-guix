;;; Not really how much of this is actually needed but didn't feel like debugging
;;; copied from gnu packages emulators

(define-module (cig-guix emulators)
  #:use-module (ice-9 match)
  #:use-module (guix licenses)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix svn-download)
  #:use-module (guix hg-download)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages assembly)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages autogen)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages cdrom)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages containers)
  #:use-module (gnu packages cross-base)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages digest)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages fltk)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages fribidi)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages graphics)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages image)
  #:use-module (gnu packages libedit)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages music)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages upnp)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xiph)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages web)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system qt)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system python)
  #:use-module (guix build-system qt))

(define-public citra
  ;; we use the 'nightly' revision, picking stable features
  (let ((revision "1785")
	(commit "baecc18d8c5365af0dddb231bc8c0a9c03850bf6"))
    (package
     (name "citra")
     (version (git-version "0" revision commit))
     (source
      (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/citra-emu/citra-nightly")
             (commit
              (string-append "nightly-" revision))
             ;;some submodules can't be avoided
             ;;TODO devendor the rest
             (recursive? #t)))
       (sha256
	(base32
         "1grkrrxs1497i51spgnwmgfkqgkm7gplylhcrk67agaklx65d5s9"))
       (file-name (git-file-name name version))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; Remove as much external stuff as we can
           ;; f.e. some files in boost are still needed
           (for-each (lambda (dir)
                       (delete-file-recursively
                        (string-append "externals/" dir)))
                     '("android-ifaddrs"
                       "catch"
                       "discord-rpc"
                       "getopt"
                       "libyuv"
                       "libressl"
                       "libusb"))
           ;; Clean up source.
           (for-each delete-file
                     (find-files "." ".*\\.(bin|dsy|exe|jar|rar)$"))
           #t))))
     (build-system qt-build-system)
     (arguments
      (list
       #:configure-flags
       #~(list
          "-DUSE_SYSTEM_BOOST=ON"
          "-DCITRA_USE_BUNDLED_FFMPEG=OFF"
          "-DCITRA_USE_BUNDLED_QT=OFF"
          "-DCITRA_USE_BUNDLED_SDL2=OFF"
          "-DCITRA_ENABLE_COMPATIBILITY_REPORTING=OFF"
          "-DCMAKE_BUILD_TYPE=Release"
          "-DENABLE_COMPATIBILITY_LIST_DOWNLOAD=OFF"
          "-DENABLE_FFMPEG_AUDIO_DECODER=ON"
          "-DENABLE_QT_TRANSLATION=ON"
          "-DENABLE_WEB_SERVICE=OFF")
       #:phases
       #~(modify-phases %standard-phases
			(add-before 'configure 'delete-check
				    (lambda _
				      (substitute* "CMakeLists.txt"
						   (("check_submodules_present\\(\\)")""))))
			(add-after 'qt-wrap 'wrap-gst-plugins
				   (lambda* (#:key outputs #:allow-other-keys)
				     (for-each
				      (lambda (bin)
					(wrap-program bin)
					`("GST_PLUGIN_SYSTEM_PATH" prefix
					  (,(getenv "GST_PLUGIN_SYSTEM_PATH"))))
				      `(,(search-input-file outputs "bin/citra")
					,(search-input-file outputs "bin/citra-qt"))))))))
     (native-inputs
      (list catch2 doxygen pkg-config))
     (inputs
      (list boost
            curl
            ffmpeg
            gst-plugins-bad-minimal      ;camera-support
            libfdk
            libpng
            libusb
            libxkbcommon
            openssl
            pulseaudio
            qtbase-5
            qtmultimedia-5
            qttools-5
            qtwayland-5
            sdl2))
     (propagated-inputs (list xdg-utils shared-mime-info))
     (home-page "https://citra-emu.org")
     (synopsis "Nintendo 3DS Emulator")
     (description "Citra is an experimental emulator/debugger for the Nintendo 3DS
written in C++.  It emulates a subset of the Nintendo 3DS' hardware.")
     (license gpl2+))))
