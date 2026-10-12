FROM rocm/dev-ubuntu-22.04:latest AS builder

RUN apt-get update && apt-get install -y build-essential cmake git

RUN git clone https://github.com/ggerganov/llama.cpp.git /app
WORKDIR /app

# Compile for RDNA 3 architecture
RUN cmake -B build -DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1102 -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build --config Release --target llama-server -j$(nproc)

FROM rocm/dev-ubuntu-22.04:latest
COPY --from=builder /app/build/bin/llama-server /usr/local/bin/

EXPOSE 8080

# Execute strictly for embeddings calculation (--embedding)
ENTRYPOINT ["llama-server"]
CMD ["--hf-repo", "nomic-ai/nomic-embed-text-v1.5-GGUF", \
     "--hf-file", "nomic-embed-text-v1.5.Q8_0.gguf", \
     "--n-gpu-layers", "999", \
     "--embedding", \
     "--host", "0.0.0.0", \
     "--port", "8080"]
