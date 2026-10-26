#!/bin/sh
# Touch ID for sudo. /etc/pam.d/sudo_local is the file Apple keeps across macOS
# updates; it is created from Apple's template only when missing, so an apply
# on a configured Mac asks for nothing.
[ "$(uname)" = Darwin ] || exit 0
f=/etc/pam.d/sudo_local
grep -qs '^auth[[:space:]].*pam_tid\.so' "$f" && exit 0
echo "Enabling Touch ID for sudo ($f)"
sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee "$f" >/dev/null
