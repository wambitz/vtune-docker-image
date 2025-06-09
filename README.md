# VTune Hotspots Profiling Inside Docker

One‑command workflow to build a C++ demo workload and collect Intel VTune **Hotspots** data entirely inside a container, while keeping results and file ownership clean on the host.

---

## Directory layout

```text
.
├── build_image.sh   # build the vtune‑docker image (wrapper around `docker build`)
├── build.sh         # compile `prime_counter` inside the image
├── CMakeLists.txt   # minimal CMake project (‑g, -fno‑omit‑frame‑pointer)
├── Dockerfile       # Ubuntu 24.04 + oneAPI VTune CLI base
├── main.cpp         # naïve prime counter – burns CPU
└── run_vtune.sh     # run VTune Hotspots, results in `vtune_results/`
```

---

## 1 · Prerequisites

| Tool   | Version | Notes                                            |
| ------ | ------- | ------------------------------------------------ |
| Docker | ≥ 20.10 | `docker --version`                               |
| Linux  | x86‑64  | Intel CPU optional for HW‑event metrics (see §5) |

> **Kernel setting** – VTune needs unrestricted ptrace:
>
> ```bash
> sudo sysctl -w kernel.yama.ptrace_scope=0   # temporary (reverts on reboot)
> ```
>
> Make it permanent by writing `kernel.yama.ptrace_scope = 0` to
> `/etc/sysctl.d/10-ptrace.conf` and running `sudo sysctl --system`.

---

## 2 · Build the image

```bash
./build_image.sh
# (drops an image called vtune-docker:latest)
```

`build_image.sh` is a thin wrapper around:

```bash
docker build -t vtune-docker \
  --build-arg UID=$(id -u) --build-arg GID=$(id -g) .
```

The `UID/GID` args ensure everything created inside the container is owned by *you* on the host.

---

## 3 · Compile the demo binary

```bash
./build.sh
```

Generates `build/prime_counter` inside the repo. The script mounts the working directory into the container and calls:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

---

## 4 · Collect a Hotspots profile

```bash
./run_vtune.sh
```

Key runtime flags:

* `--cap-add=SYS_PTRACE --cap-add=SYS_ADMIN` – required for sampling.
* `--security-opt seccomp=unconfined` – avoid seccomp blocking perf events.
* `--pid=host` – optional but allows profiling host PIDs if you ever need it.

On completion, `vtune_results/` appears next to your code.

### View the report

* **VTune GUI installed**

  ```bash
  vtune-gui vtune_results
  ```
* **CLI only**

  ```bash
  vtune -report hotspots -r vtune_results
  ```

---

## 5 · (Optional) Micro‑architecture metrics

Function‑level hotspots come from user‑mode sampling and are usually enough.
To unlock *L1/L2 misses, branch mispredicts*, etc., load VTune’s sampling driver (`sep`, `vtsspp`) **on the host**:

```bash
sudo /opt/intel/oneapi/vtune/latest/sepdk/src/setup.sh   # build + insmod
```

Then run the container with the device nodes exposed:

```bash
--device /dev/sep_drv --device /dev/pax    # or simply --privileged
```

---

## 6 · Clean up

```bash
docker image rm vtune-docker
rm -rf build vtune_results
```

---

## 7 · Troubleshooting

| Symptom                                         | Fix                                                          |
| ----------------------------------------------- | ------------------------------------------------------------ |
| `ptrace_scope` error                            | `sudo sysctl -w kernel.yama.ptrace_scope=0`                  |
| No stack traces / empty call stacks             | Make sure compile flags include `-g -fno-omit-frame-pointer` |
| Results owned by **root**                       | Scripts already pass `-u $(id -u):$(id -g)`                  |
| `Microarchitecture performance insights …` warn | Install & load the sampling driver or ignore (user‑mode OK)  |

---

### License

Demo code © 2025 Julio Castillo Cruz, MIT License.
Intel VTune binaries are covered by the Intel End‑User License Agreement.
