{ config, lib, pkgs, modulesPath, ... }:

let
  xstartup = pkgs.writeShellScript "xstartup.sh" ''
    . /etc/profile
    PATH=$PATH:/run/current-system/sw/bin ${pkgs.lxterminal}/bin/lxterminal -e "
      set -ex
      mkdir /nfsroot
      mount 10.0.0.1:/ /nfsroot
      bash
    " &
    exec ${pkgs.icewm}/bin/icewm-session
  '';
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=1M
  '';
  boot.kernel.sysctl = { "vm.dirty_writeback_centisecs" = 6000; };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "nfs" ];
  boot.initrd = {
    # Hier müssen noch die Kernelmodule für die eigenen physischen
    # Netzwerkkarten ergänzt werden!
    availableKernelModules = [ "nfsv4" "ne2k-pci" "r8169" "e1000" "e1000e" ];
    systemd = {
      enable = true;
      initrdBin = with pkgs; [ nfs-utils iproute2 less util-linux linux-firmware pciutils iputils ];
      emergencyAccess = true;
    };
    network = {
      enable = true;
      flushBeforeStage2 = false;
    };
  };
  boot.loader.grub.enable = false;

  hardware.enableRedistributableFirmware = true;

  networking = {
    useNetworkd           = false;
    hostName              = "lovelace";
    firewall.enable       = false;
    networkmanager.enable = false;
    wireless.enable       = false;
  };

  services.logrotate.enable       = false;
  documentation.enable            = false;
  documentation.doc.enable        = false;
  hardware.graphics.enable        = false;
  services.speechd.enable         = false;
  services.pipewire.enable        = false;
  services.pulseaudio.enable      = false;
  programs.bash.completion.enable = false;

  # Grafische Bootanimation deaktivieren
  boot.plymouth.enable = false;

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  users.users.root.hashedPassword = "$y$j9T$6qEVO9p2eUFmb9sWIT.6s/$ibWC1J2RcfeFqtvV3tnakuq5FcjRFlCOvnQ6qNVkf/D";

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
    };
    "/nix/.ro-store" = {
      fsType = "nfs";
      device = "10.0.0.1:/nix/store";
      options = [ "ro" ];
      neededForBoot = true;
    };
    "/nix/store" = {
      overlay = {
        lowerdir = [ "/nix/.ro-store" ];
        upperdir = "/nix/.rw-store/store";
        workdir = "/nix/.rw-store/work";
      };
      neededForBoot = true;
    };
  };
  boot.nixStoreMountOpts = [ "rw" ];

  environment.systemPackages = with pkgs; [
    bash vim sshfs screen socat iputils parted cryptsetup
    btrfs-progs firefox
  ];

  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
  };
  services.libinput = {
    enable = true;
    touchpad.middleEmulation = true;
  };

  systemd.services.xstartup = {
    after = [ "graphical.target" ];
    wantedBy = [ "graphical.target" ];
    description = "xstartup";
    script = ''
      cookie=$(mcookie)
      xauth -f /root/.Xauthority source - <<EOF
      add lovelace:1 . $cookie
      add lovelace/unix:1 . $cookie
      EOF
      # logic lifted from sx
      trap 'DISPLAY=:1 exec ${xstartup} & wait "$!"' USR1
      (trap "" USR1 && exec X :1 -noreset -auth /root/.Xauthority) & pid=$!
      wait "$pid"
    '';
    serviceConfig = {
      User = "root";
      TTYPath = "/dev/tty7";
      UtmpIdentifier = "tty7";
      UtmpMode = "user";
      StandardOutput = "journal";
      #ExecStartPre = "${pkgs.kbd}/bin/chvt 7";
    };
    path = with pkgs; [ bash util-linux coreutils xorg.xauth xorg.xorgserver coreutils xterm ];
  };

  system.build.pxeTree = pkgs.linkFarm "pxe-tree" [
    {
      name = "initrd";
      path = "${config.system.build.initialRamdisk}/initrd";
    }
    {
      name = "bzImage";
      path = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
    }
    {
      name = "nix-path-registration";
      path = "${pkgs.buildPackages.closureInfo { rootPaths = [ config.system.build.toplevel ]; }}/registration";
    }
    {
      name = "pxelinux.cfg/default";
      path = pkgs.writeScript "default" ''
        default Start
        label Start
          kernel /bzImage
          append initrd=/initrd init=${config.system.build.toplevel}/init rd.systemd.debug_shell ${toString config.boot.kernelParams}
      '';
    }
  ];
}
