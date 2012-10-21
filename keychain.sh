#!/bin/sh
# Load keychain to handle ssh and gpg keys
export SSH_ASKPASS=/usr/bin/ksshaskpass
eval `keychain --eval id_rsa 1338F289`
#eval `keychain --eval id_rsa 1A6E3377`
#$HOME/.keychain/`hostname`-sh
#$HOME/.keychain/`hostname`-sh-gpg
