component "yaml-cpp" do |pkg, settings, platform|
  pkg.url "git://github.com/jbeder/yaml-cpp.git"
  pkg.ref "refs/tags/yaml-cpp-0.6.2"

  # Build Requirements
  if platform.is_cross_compiled_linux?
    pkg.build_requires "pl-binutils-#{platform.architecture}"
    pkg.build_requires "pl-gcc-#{platform.architecture}"
    pkg.build_requires "pl-cmake"
  elsif platform.is_solaris?
    if platform.os_version == "10"
      pkg.build_requires "http://pl-build-tools.delivery.puppetlabs.net/solaris/10/pl-cmake-3.2.3-15.i386.pkg.gz"
    elsif platform.os_version == "11"
      pkg.build_requires "pl-binutils-#{platform.architecture}"
      pkg.build_requires "pl-gcc-#{platform.architecture}"
      pkg.build_requires "pl-cmake"
    end
  elsif platform.is_windows?
    pkg.build_requires "pl-toolchain-#{platform.architecture}"
    pkg.build_requires "cmake"
  elsif platform.is_macos?
    pkg.build_requires "cmake"
  elsif platform.is_aix?
    # Moved to platform def
    #pkg.build_requires "http://pl-build-tools.delivery.puppetlabs.net/aix/#{platform.os_version}/ppc/pl-gcc-5.2.0-1.aix#{platform.os_version}.ppc.rpm"
    pkg.build_requires "http://pl-build-tools.delivery.puppetlabs.net/aix/#{platform.os_version}/ppc/pl-cmake-3.2.3-2.aix#{platform.os_version}.ppc.rpm"

    # Since we're using system GCC but pl-cmake, we need to let cmake know where to find libstdc++ and libgcc_a:
    # pkg.environment "PL_TOOLS_ROOT", "/opt/freeware/lib"
  else
    pkg.build_requires "pl-gcc"
    pkg.build_requires "make"
    pkg.build_requires "pl-cmake"
  end

  # Build-time Configuration
  cmake = "#{settings[:tools_root]}/bin/cmake"
  cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/pl-build-toolchain.cmake"
  make = 'make'
  mkdir = 'mkdir'

  if platform.is_aix?
    # We're using pl-cmake with the IBM toolbox gcc:
    cmake = "/opt/pl-build-tools/bin/cmake"
    # The toolchain file sets pl-gcc as the compiler; Let cmake use the system gcc instead:
    cmake_toolchain_file = ""
  elsif platform.is_cross_compiled_linux?
    # We're using the x86_64 version of cmake
    cmake = "/opt/pl-build-tools/bin/cmake"
    cmake_toolchain_file = "-DPL_TOOLS_ROOT=/opt/freeware -DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
  elsif platform.is_solaris?
    if platform.os_version == "11"
      make = '/usr/bin/gmake'
    end
    # We always use the i386 build of cmake, even on sparc
    cmake = "/opt/pl-build-tools/i386-pc-solaris2.#{platform.os_version}/bin/cmake"
    cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
    pkg.environment "PATH" => "$$PATH:/opt/csw/bin"
  elsif platform.is_macos?
    cmake_toolchain_file = ""
    cmake = "/usr/local/bin/cmake"
  elsif platform.is_windows?
    make = "#{settings[:gcc_bindir]}/mingw32-make"
    mkdir = '/usr/bin/mkdir'
    pkg.environment "PATH", "$(shell cygpath -u #{settings[:gcc_bindir]}):$(shell cygpath -u #{settings[:ruby_bindir]}):/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0"
    pkg.environment "CYGWIN", settings[:cygwin]
    cmake = "C:/ProgramData/chocolatey/bin/cmake.exe -G \"MinGW Makefiles\""
    cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/pl-build-toolchain.cmake"
  end

  # Build Commands
  pkg.build do
    [ "#{mkdir} build-shared",
      "cd build-shared",
      "#{cmake} \
      #{cmake_toolchain_file} \
      -DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DYAML_CPP_BUILD_TOOLS=0 \
      -DYAML_CPP_BUILD_TESTS=0 \
      -DBUILD_SHARED_LIBS=ON \
      .. ",
      "#{make} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1)",
      "cd ../",
      "#{mkdir} build-static",
      "cd build-static",
      "#{cmake} \
      #{cmake_toolchain_file} \
      -DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DYAML_CPP_BUILD_TOOLS=0 \
      -DYAML_CPP_BUILD_TESTS=0 \
      -DBUILD_SHARED_LIBS=OFF \
      ..",
      "#{make} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"
    ]
  end

  pkg.install do
    [ "cd build-shared",
      "#{make} install",
      "cd ../build-static",
      "#{make} install"
    ]
  end
end