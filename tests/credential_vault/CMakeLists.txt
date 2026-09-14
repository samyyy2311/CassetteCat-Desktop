cmake_minimum_required(VERSION 3.24)
project(CredentialVaultProbe LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Core)
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBSECRET REQUIRED IMPORTED_TARGET libsecret-1)

add_executable(credential_vault_probe
    probe.cpp
    ../../src/credential_vault.cpp
    ../../src/credential_vault.h
)
target_include_directories(credential_vault_probe PRIVATE ../../src)
target_compile_definitions(credential_vault_probe PRIVATE CASSETTECAT_HAVE_LIBSECRET=1)
target_link_libraries(credential_vault_probe PRIVATE Qt6::Core PkgConfig::LIBSECRET)
