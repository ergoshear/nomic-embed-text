# Nomic Embed Text v1.5 on AMD RDNA 3 (gfx1102)

This repository builds a ROCm `llama.cpp` embedding server for an AMD RDNA 3
GPU (`gfx1102`). The container supplies ROCm user space; the Linux host
must provide a working AMDGPU driver and expose `/dev/kfd` and `/dev/dri`.

## Model and context

- Model: [`nomic-ai/nomic-embed-text-v1.5-GGUF`](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF),
  `nomic-embed-text-v1.5.Q8_0.gguf` (about 146 MB). The downloader pins the
  Hugging Face revision on first use, resumes partial downloads, and verifies
  the file against its LFS SHA256. Set `MODEL_REVISION` to a full commit SHA on
  the first download to select a specific revision; use a new volume to change
  the saved revision.
- The default context is 2,048 tokens, the context llama.cpp uses for this GGUF
  without context extension. Although the original model supports 8,192 tokens,
  llama.cpp needs YaRN RoPE scaling to reach that length. This image keeps the
  default at 2,048 to avoid silently changing embedding behavior.
- The server enables embedding mode and mean pooling. Prefix each input with
  the task instruction appropriate to its use, such as `search_query: ` for
  search queries and `search_document: ` for indexed documents.

## Build and download

Run from this repository root. These examples use Podman; Docker can use the
same device mappings.

```sh
podman build --format docker -t nomic-embed-text-gfx1102 .
podman volume create nomic-embed-text-model
podman run --rm -v nomic-embed-text-model:/models \
  --entrypoint /usr/local/bin/download-model nomic-embed-text-gfx1102
```

The public model does not need a token. For authenticated downloads, pass
`HF_TOKEN` or `HUGGINGFACE_API_KEY` only to the download container. The model is
stored in the named volume, not in the image or repository.

## Run the server

```sh
podman run -d --name nomic-embed-text \
  --device /dev/kfd --device /dev/dri \
  --group-add keep-groups \
  -v nomic-embed-text-model:/models:ro \
  -p 127.0.0.1:8080:8080 \
  nomic-embed-text-gfx1102
podman logs -f nomic-embed-text
```

`GPU_LAYERS`, `CTX_SIZE`, `PARALLEL`, `THREADS`, `BATCH_SIZE`, and
`UBATCH_SIZE` can override the defaults. Keep the API bound to loopback as
shown. If it must be reachable remotely, put it behind an authenticated TLS
proxy.

Check readiness and request a vector from the OpenAI-compatible embeddings
endpoint:

```sh
curl -fsS http://127.0.0.1:8080/health
curl -fsS http://127.0.0.1:8080/v1/embeddings \
  -H 'Content-Type: application/json' \
  -d '{"model":"nomic-embed-text-v1.5","input":"search_query: What is vector search?"}'
```

## Validation status

The image has not been built or run on the target host. Confirm that ROCm sees
the GPU, then verify model loading and an embeddings request on the machine
before relying on the service.
