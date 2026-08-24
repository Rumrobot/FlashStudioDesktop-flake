{
  lib,
  makeFontsConf,
  nanum,
  pkgs,
  source,
  withNvidiaGLWorkaround ? false,
}: let
  src = pkgs.fetchurl {
    inherit (source) url;
    hash = source.sha256;
  };
  pname = "flash-studio";
  inherit (source) version;

  appimageContents = pkgs.appimageTools.extract {inherit pname version src;};

  # Upstream bug: a wxButton with a stock ID and an empty label makes GTK attach a plain
  # GtkImage, which wx casts to wxGtkImage and derefs through a NULL m_provider -> segfault.
  stockButtonFix = pkgs.runCommandCC "wx-stock-button-fix" {} ''
    mkdir -p $out/lib
    cat > fix.c <<'EOF'
    #define _GNU_SOURCE
    #include <dlfcn.h>
    #include <string.h>
    #include <errno.h>
    void* gtk_button_get_image(void* button)
    {
        static void* (*real)(void*);
        static const char* (*type_name)(void*);
        if (!real) real = dlsym(RTLD_NEXT, "gtk_button_get_image");
        if (!type_name) type_name = dlsym(RTLD_DEFAULT, "g_type_name_from_instance");
        void* img = real ? real(button) : 0;
        if (img && type_name
            && strcmp(program_invocation_short_name, "flash studio") == 0
            && strcmp(type_name(img), "wxGtkImage") != 0)
            return 0;
        return img;
    }
    EOF
    $CC -shared -fPIC -o $out/lib/libwx-stock-button-fix.so fix.c
  '';

  # libFlashNetwork.so links Ubuntu's libcurl, which has versioned
  # symbols (CURL_OPENSSL_4).
  curlVersioned = pkgs.curl.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ ["--enable-versioned-symbols"];
  });

  # Workaround for crash due to missing font
  # https://github.com/OrcaSlicer/OrcaSlicer/issues/11641
  fontsConf = makeFontsConf {
    fontDirectories = [nanum];
    impureFontDirectories = [];
    includes = [];
  };
in
  pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs:
      with pkgs;
        map lib.getLib [
          zstd
          libmspack
          libsoup_3
          webkitgtk_4_1
          glib-networking

          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-plugins-good
        ];

    profile = ''
      export LD_LIBRARY_PATH=${lib.getLib curlVersioned}/lib:/usr/lib64:/usr/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      export FONTCONFIG_FILE=${fontsConf}
      export GIO_EXTRA_MODULES=/usr/lib/gio/modules
      export SSL_CERT_FILE=''${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}
      export GTK_THEME=''${GTK_THEME:-Adwaita}
      export LD_PRELOAD=${stockButtonFix}/lib/libwx-stock-button-fix.so''${LD_PRELOAD:+:$LD_PRELOAD}
      export WEBKIT_DISABLE_COMPOSITING_MODE=1
      ${lib.optionalString withNvidiaGLWorkaround ''
        export __GLX_VENDOR_LIBRARY_NAME=mesa
        export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
        export MESA_LOADER_DRIVER_OVERRIDE=zink
        export GALLIUM_DRIVER=zink
        export WEBKIT_DISABLE_DMABUF_RENDERER=1
      ''}
    '';

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/Orca-Flashforge.desktop $out/share/applications/flash-studio.desktop
      install -Dm444 ${appimageContents}/usr/share/icons/hicolor/192x192/apps/Orca-Flashforge.png \
        $out/share/icons/hicolor/192x192/apps/flash-studio.png
      substituteInPlace $out/share/applications/flash-studio.desktop \
        --replace-fail 'Exec=AppRun %F' 'Exec=flash-studio %F' \
        --replace-fail 'Name=Orca-Flashforge' 'Name=Flash Studio Desktop' \
        --replace-fail 'Icon=Orca-Flashforge' 'Icon=flash-studio'
    '';

    meta = {
      description = "Flash Studio Desktop is an open source slicer for FDM printers.";
      homepage = "https://github.com/FlashForge/Orca-Flashforge";
      license = lib.licenses.agpl3Only;
      mainProgram = "flash-studio";
      platforms = ["x86_64-linux"];
    };
  }
