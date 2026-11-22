## -- Quick opinion note -- 
Although I am not a big fan of the AI craze and it's egregious waste of power and water, and the stolen media many frontier models were trained on, and the effect it has on people's ability to think independently and creatively, among other things... I do understand that keeping up with relevant technology and understanding how it works is important. So regardless of my personal opinions on how these tools may or may not work, I decided to set up a local environment and see what I can do for it. With that out of the way, my guide:

You can skip to the [Setup Guide](#setup-guide) if you don't want to read the rationalle.

# Self Hosted Local LLM stack
This guide will include helpful information for where to start based on what you have available. It will follow my personal experience, so your mileage may very.

# Core components

### Locally hosted (easy)
If you want the easy way, [LMstudio](https://lmstudio.ai/) has been my choice here, primarily due to it's clean UI and easy configuration for things like offloading for Mixture of Experts (MoE) layers. It's an end to end tool that handles model downloads, a local "Link" system for integration with your IDE, simple chat window

### Dedicated Server (My current setup)
If you want more than what LM studio can offer, or want multiple devices to be able to call models at the same time, you'll need to look at setting up a dedicated server with at least 2 components: a model "engine", and an interface.

#### Model engine
In my mind there are two choices here for home use:

**Ollama (Easy)** 
- + The simplest to set up
- + Integrates so well into the interface layer that it's practically set and forget.
- - Only supports single sessions (one stream of response at a time, with a queue)
- - No MoE layer offload support

**llama.ccp + llama swap (Harder, My current choice)**
- + Supports MoE offloading
- + Supports multiple concurrent sessions (as long as your hardware can handle it)
- - Manual configuration for adding new models
- - Poorer integration with frontend
#### Interface

To be honest, there's really only one choice here. [OpenWebUI](https://docs.openwebui.com/) is the best foundation for this as it has a simple to integrate web interface and an OpenAI compatible restAPI, giving you both out of the gate. Though advance warning, OpenwebUI is a sea of menus that are not intuitive. 
# My current environment

#### VM 
Hosting both llama.cpp and llama swap on bare metal, openwebui in a container.
- OS: Ubuntu 22.04 LTS
- CPU: 16c 16t 
- RAM: 32GB DDR4 ECC
- Storage: 250GB ext4 
- GPU RTX 3080 Ti 12GB


# Setup guide
This setup guide mirrors my exact setup. If you would rather use podman instead of docker, or run everything in containers instead of the engine layer on bare metal, be my guest.

## DISCLAIMER
I'm not an expert. I use only gguf encoded models in llama and ollama because they work reliably.
## Prerequisites 
- A Ubuntu VM with your GPU connected
- - For nvidia -
	- nvidia drivers **and** nvidia cuda toolkit installed (TLDR in docs/cuda-speedrun.md, ymmv). I am using driver 565 with Cuda toolkit 12.4
	- nvidia-smi or nvtop
	- `git` (usually installed already)
	- `cmake` or your favorite clang compiler.
	- `docker`, preferably installed following the [official docs](https://docs.docker.com/engine/install/ubuntu/) 
## Collect software

### Hugging Face CLI
Easiest to grab. get it first:
```sh
curl -LsSf https://hf.co/cli/install.sh | bash
hf --version
```
Download a model of your choice. For this example, I will use unsloth's Gemma 4 E4B variant. It's about 4GB.
```sh
hf download hf://unsloth/gemma-4-E4B-it-qat-GGUF/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf --local-dir ~/models
```
- `--local-dir` specifies a download location for your models. Create the folder ahead of time.

### llama.cpp
Grab a copy of the llama.cpp repository. To ensure your GPU and Cuda versions are properly detected, compiling from main is recommended.
Clone the repo and move to it
```sh
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
```

Build llama-server (Clear the build folder if you've already tried to build once)

**##IMPORTANT##** 
- Make sure to specify the cuda architecture matching your hardware/cuda version. See the [REFERENCE TABLE](https://developer.nvidia.com/cuda/gpus), convert the major.minor version number to a two digit num. So 8.6 uses `-DCMAKE_CUDA_ARCHITECTURES=86`
- `-DCMAKE_CUDA_COMPILER` and `-DCUDAToolkit_ROOT` point at YOUR cuda install. If you have a version different than 12.4, change the path. 
- `-j1` on the final step specifies the threads used to compile and sets it to 1. I had issues with multithreaded compiles but ymmv. 
```sh
rm -rf build # if you already built once

cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=86 \
  -DCMAKE_CUDA_COMPILER=/usr/local/cuda-12.4/bin/nvcc \
  -DCUDAToolkit_ROOT=/usr/local/cuda-12.4

cmake --build build --target llama-server -j1
```

Once bult, run a check to ensure your GPU is detected.
```sh
./build/bin/llama-server --list-devices    # should list your GPU
```
If it is detected, you're good! if not, Check the [llama.cpp build guide](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)

### llama-swap
Download the latest [release of llama-swap](https://github.com/mostlygeek/llama-swap/releases) (v274 at the time of writing)
```sh 
wget https://github.com/mostlygeek/llama-swap/releases/download/v274/llama-swap_274_linux_amd64.tar.gz -O llama-swap_274_linux_amd64.tar.gz
```

Expand the archive
```sh
tar -xvf llama-swap_274_linux_amd64.tar.gz
```

Create a starter config.yaml file using your favorite text editor.

Contents:
```yaml
healthCheckTimeout: 300
  Gemma-4-E4B-smol:
    cmd: >
      /path/to/your/llama.cpp/build/bin/llama-server --port ${PORT} --jinja
      -m path/to/your/models/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf
      -ngl auto -c 131072
      --temp 1.0 --top-k 64 --top-p 0.95
    ttl: 300
```
- `-c` context size
- `-ngl` max. number of layers to store in VRAM, either an exact number, 'auto', or 'all'
- **Specific per model, read hf page for your model before setting**
	- `--top-k` sampling (default: 40, 0 = disabled). 
	- `--top-p` top-p sampling (AKA nucleus sampling, helps reduce loop responses)

For everything ~OUTSIDE~ of the `cmd` block, reference the [llama-swap config example](https://github.com/mostlygeek/llama-swap/blob/main/docs/config.example.yaml) 
For everything ~INSIDE~ of the `cmd` block, reference the [llama.cpp server guide](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md) 

Save and exit your config file, and try running llama-swap
```sh
./llama-swap
```
You should get `[INFO] llama-swap listening on http://0.0.0.0:PORT` with your desired port specified. Open another terminal, and try hitting the api interface with curl:
```sh
curl http://localhost:PORT/v1/chat/completions   -H "Content-Type: application/json"   -d '{"model":"Gemma-4-E4B-smol","messages":[{"role":"user","content":"tell me a short story in 100 words"}]}'
```
Give it a minute, it has to load the model into system ram, then VRAM, but you should get a reply in JSON format. IE:
```json
{
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Elara found the antique music box hidden in her grandfather's attic. It was carved with scenes of a vibrant, forgotten summer. When she wound the tiny silver key, a melancholic waltz filled the dusty air, a rhythm of lost laughter.\n\nA faded photograph slipped from the compartment. It showed a young man, smiling, holding her hand—her grandfather, whom she believed had died decades ago. \n\nThe music swelled, impossibly sweet. He wasn't a ghost; he was a memory preserved in mahogany and sound. The box played on, a beautiful echo of a life rediscovered."
      }
    }
  ],
  "created": 1795324167,
  "model": "/path/to/your/models/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf",
  "system_fingerprint": "b12531-e4b620af1",
  "object": "chat.completion",
  "usage": {
    "completion_tokens": 499,
    "prompt_tokens": 27,
    "total_tokens": 526,
    "prompt_tokens_details": {
      "cached_tokens": 16
    }
  },
  "id": "chatcmpl-TgmzII9VSU69eKQt5RIHHmQMYJ3gh420",
  "timings": {
    "cache_n": 16,
    "prompt_n": 11,
    "prompt_ms": 52.9,
    "prompt_per_token_ms": 4.809090909090909,
    "prompt_per_second": 207.93950850661625,
    "predicted_n": 499,
    "predicted_ms": 4213.569,
    "predicted_per_token_ms": 8.460981927710844,
    "predicted_per_second": 118.18959176887812
  }
}
```

If it replies, your configuration is correct!

If not, **Refer to the llama-swap logs for errors**. By default, llama-swap exposes a helper web ui available at `http://ip:port/ui/`. Logs for the proxy layer and the "upstream" llama-server can be seen there.

I highly suggest configuring llama-swap as a systemd service so it starts on boot and runs in the background. Here's my systemd config:
Path: `/etc/systemd/system/llama-swap.service`
Content:
```INI
[Unit]
Description=llama-swap model proxy
After=network-online.target
Wants=network-online.target  

[Service]
Type=simple
User=YOURUSER
WorkingDirectory=/home/YOURUSER/LLAMASWAP
Environment=LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64
ExecStart=/path/to/LLAMASWAP/llama-swap --config /path/to/config.yaml --listen 0.0.0.0:8083
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
sudo systemctl daemon-reload
sudo systemctl enable --now llama-swap
journalctl -u llama-swap -f
curl http://localhost:8083/v1/models
```

**IMPORTANT**
- Make sure you set the `WorkingDirectory`, `Environment`, and `ExecStart` values to reflect your configuration.

## OpenWebUI
Personally I prefer to install Openwebui via docker. It's the easiest to manage and update. 
[Reference guide](https://docs.openwebui.com/getting-started/quick-start)

Generate a webUI secret key with openssl rand 32. Copy that and replace `REPLACETHISKEY` in the docker compose content with it.
```sh
openssl rand -hex 32
```

Create a docker compose file for openwebUI:
```yaml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:dev
    ports:
      - "3000:8080"
    volumes:
      - open-webui:/app/backend/data
    extra_hosts:
      - host.docker.internal:host-gateway
    environment:
      - WEBUI_SECRET_KEY=REPLACETHISKEY
    restart: unless-stopped

volumes:
  open-webui:
```
The PVC volume ensures you don't wipe your changes when you update. You can mount this to a path on your host if desired.

Stand up the docker config stack with `docker compose up -d`

Once set up, you can just update the container image with `docker compose pull` and then `docker compose up -d` again.

Watch the logs. Once you see a great big `OPEN WEBUI` in ascii art, it should be accessible via webUI. Browse to the web interface: `http://YOUR_SERVERS_IP:3000`

Follow the prompts to set up your admin account.

Once on the main webpage, we need to connect OpenWebUI to llama-swap so they can talk to each other.

Open the settings by clicking on your icon in the bottom left, then settings.

On the left side bar, select Connections (Under the Admin > AI category)

Under "OpenAI API", Click the + to add an OpenAI compatible server.

In the pop out, set:
- Connection Type to `local`
- URL to the address of your llamaswap endpoint. 
	- Usually `http://IP:Port/v1` 
	- Example: `http://10.10.44.223:8083/v1` 
- Auth type to `none`
Click the Refresh button next to the URL to test the connection. It should say "Server Connection Verified" in a green notification box in the top right.

That's it! Try out your newly configured LLM stack by hitting "New Chat", selecting your model in the bottom right, then sending it a message!
