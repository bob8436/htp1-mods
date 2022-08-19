# HTP-1 Firmware modifications

This repo exists to address the [bootlooping](https://www.avsforum.com/threads/the-official-monoprice-monolith-htp-1-owners-thread.3112176)
issues with the Monoprice HTP-1 AV Processor. The output of these scripts is
a runnable SD-card image - it will not modify the HTP-1's internal storage.


## Building

This build has been tested on Debian 11. The build uses Docker to contain
scripts in a controlled environment and run scripts "inside" the eventual
filesystem that runs on the HTP-1. As the HTP-1 is ARM-based, the ability to
run ARM-based Docker containers is essential. These following commands will
ensure you can run the ARM containers (Debian/Ubuntu):

```
sudo apt-get install qemu binfmt-support qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

