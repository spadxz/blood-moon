#pragma once

#include <QString>

namespace scarlett::fonts {

/// makes "Material Symbols Rounded" available. end4 installs it system-wide, so
/// that copy wins; otherwise the one installed beside scarlett (or left in the
/// build tree) is loaded.
void loadIconFont();
/// "Material Symbols Rounded"
QString iconFamily();

/// prefers OPPO Sans when installed locally, then makes Google Sans Flex
/// available from the system or beside scarlett before interfaceFamily().
void loadInterfaceFont();

/// OPPO Sans when installed, then Google Sans Flex, Google Sans, Rubik, Inter,
/// Noto Sans, or the platform default.
QString interfaceFamily();
/// the platform's own fixed-width face: a generic name like "monospace"
/// means nothing to macos, which then searches every family for it
QString fixedFamily();

} // namespace scarlett::fonts
