class Movgrab < Formula
  desc "Downloader for youtube, dailymotion, and other video websites"
  homepage "https://sites.google.com/site/columscode/home/movgrab"
  url "https://github.com/ColumPaget/Movgrab/archive/refs/tags/3.1.2.tar.gz"
  sha256 "30be6057ddbd9ac32f6e3d5456145b09526cc6bd5e3f3fb3999cc05283457529"
  license "GPL-3.0-or-later"
  revision 7

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "00bae61b99036c125722e286765989750625ea2e101cb72b423d66b6d0e89885"
    sha256 cellar: :any,                 arm64_ventura:  "2125f5ed70f10bc4a52fe12c2039bac9c5962fbc11279649a4afcb74edafbe25"
    sha256 cellar: :any,                 arm64_monterey: "6862be98fc9700fe5387119419841f26933e19914cb5cc29cc1740ddbc7f5c91"
    sha256 cellar: :any,                 sonoma:         "19b7eca42fa3da28533ebc1fcd5d591829945c9437e95856eeeb0e7866da7f91"
    sha256 cellar: :any,                 ventura:        "be017c6a743b1e9e2da0fd70e84929e5c4922b86d4320c0a3bb9f0cd866904e3"
    sha256 cellar: :any,                 monterey:       "2e6696b7eba9cfd5ddc641e08bca87e98f03005673f17d4be0a42888598ccac5"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "a8dcd83d074d217a70c8e52ab8fb1eaf827c83c104af436ec1bbd3e0b71bcafb"
  end

  depends_on "libressl"

  uses_from_macos "zlib"

  # Fixes an incompatibility between Linux's getxattr and macOS's.
  # Reported upstream; half of this is already committed, and there's
  # a PR for the other half.
  # https://github.com/ColumPaget/libUseful/issues/1
  # https://github.com/ColumPaget/libUseful/pull/2
  patch do
    url "https://github.com/Homebrew/formula-patches/raw/936597e74d22ab8cf421bcc9c3a936cdae0f0d96/movgrab/libUseful_xattr_backport.diff"
    sha256 "d77c6661386f1a6d361c32f375b05bfdb4ac42804076922a4c0748da891367c2"
  end

  # Backport fix for GCC linker library search order
  # Upstream ref: https://github.com/ColumPaget/Movgrab/commit/fab3c87bc44d6ce47f91ded430c3512ebcf7501b
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/6e5fdfd05ce62383c7f3ac4b23ba31f5ffbac5b2/movgrab/linker.patch"
    sha256 "e23330f110cb8ea2ed29ebc99180250fa5498d53706303b4d1878dc44aa483d3"
  end

  # build patch to fix pointer conversion issues
  # upstream bug report, https://github.com/ColumPaget/Movgrab/issues/6
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/ba252015727b6f0fb362fec3edfb7c53a3f888c2/movgrab/pointer-conv.patch"
    sha256 "9b5c0bb666d92c87966e610e3c2db9736371507b646359b5421f2a4fa7d68222"
  end

  def install
    # workaround for Xcode 14.3
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    # Can you believe this? A forgotten semicolon! Probably got missed because it's
    # behind a conditional #ifdef.
    # Fixed upstream: https://github.com/ColumPaget/libUseful/commit/6c71f8b123fd45caf747828a9685929ab63794d7
    inreplace "libUseful-2.8/FileSystem.c", "result=-1", "result=-1;"

    # Later versions of libUseful handle the fact that setresuid is Linux-only, but
    # this one does not. https://github.com/ColumPaget/Movgrab/blob/HEAD/libUseful/Process.c#L95-L99
    inreplace "libUseful-2.8/Process.c", "setresuid(uid,uid,uid)", "setreuid(uid,uid)"

    system "./configure", "--enable-ssl", *std_configure_args
    system "make"

    # because case-insensitivity is sadly a thing and while the movgrab
    # Makefile itself doesn't declare INSTALL as a phony target, we
    # just remove the INSTALL instructions file so we can actually
    # just make install
    rm "INSTALL"
    system "make", "install"
  end

  test do
    system "#{bin}/movgrab", "--version"
  end
end
