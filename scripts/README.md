### Scripts

These are the scrips that modify the HTP-1. Two types of scripts are allowed, plus
arbitrary files that may also be needed. Scripts are run in lexicographic order.
Outside and inside scripts are run in the same overall ordering scheme - so an
outside script might copy a file into the root fs, followed by an inside script
that relies on it, as long as the correct naming is used.

#### Inside scripts

These scripts are run from a chroot inside of the HTP-1's file system. This means
that a `systemctl disable` command would disable a service inside the HTP-1. The
entire htp1-mods folder will be accessible at /htp1-mods

#### Outside scripts

These scripts are run from outside the HTP-1's file system. To protect the
development machine, and ensure mistakes are not made, these scripts are still
run inside a docker container. The entire htp1-mods folder will be accessible at
/htp1-mods and the HTP-1's root filesystem will be accessible at /htp1-root

#### Assets

Text files that the scripts/transforms may rely on.
