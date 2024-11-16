{
#   "17.3" = {
#     # Latest 17.x release
#     version = "550.90.05";
#     sha256 = "";
#     openSha256 = "";
#     settingsSha256 = "";
#     persistencedSha256 = "";
#     patcherSha256 = "";
#     patcherRev = "8f19e550540dcdeccaded6cb61a71483ea00d509";
#     linuxGuest = "550.90.07";
#     windowsGuest = "552.74";
#   };
#   "16.7" = {
#     # Latest 16.x release
#     version = "535.183.04";
#     sha256 = "";
#     openSha256 = null; # nvidia-open not supported
#     settingsSha256 = "";
#     persistencedSha256 = "";
#     patcherSha256 = "";
#     patcherRev = "59c75f98baf4261cf42922ba2af5d413f56f0621";
#     linuxGuest = "535.183.06";
#     windowsGuest = "538.78";
#   };
  "16.2" = rec {
    version = "535.129.03";
    sha256 = "sha256-tFgDf7ZSIZRkvImO+9YglrLimGJMZ/fz25gjUT0TfDo=";
    openSha256 = null; # nvidia-open not supported
    settingsSha256 = "sha256-QKN/gLGlT+/hAdYKlkIjZTgvubzQTt4/ki5Y+2Zj3pk=";
    persistencedSha256 = "sha256-FRMqY5uAJzq3o+YdM2Mdjj8Df6/cuUUAnh52Ne4koME=";

    patcherSha256 = "sha256-jNyZbaeblO66aQu9f+toT8pu3Tgj1xpdiU5DgY82Fv8=";
    patcherRev = "3765eee908858d069e7b31842f3486095b0846b5";
    generalSha256 = "sha256-5tylYmomCMa7KgRs/LfBrzOLnpYafdkKwJu4oSb/AC4=";
    generalVersion = version;
    linuxSha256 = "sha256-RWemnuEuZRPszUvy+Mj1/rXa5wn8tsncXMeeJHKnCxw=";
    linuxGuest = version;
    windowsSha256 = "sha256-3eBuhVfIpPo5Cq4KHGBuQk+EBKdTOgpqcvs+AZo0q3M=";
    windowsGuestFilename = "${windowsGuest}_grid_win10_win11_server2019_server2022_dch_64bit_international.exe";

    windowsGuest = "537.70";
  };
}
