# Apes Shaders

A collection of [Apes.io](https://apes.io/test) OpenGL shaders (GLSL), along with a script for extracting shaders from the game's WebAssembly (WASM) binary.

# Download the shaders

## Clone the repository
```bash
git clone https://github.com/pseudoical/apes-shaders.git
```


## [Download the ZIP](https://github.com//pseudoical/apes-shaders/archive/refs/heads/main.zip)
```text
https://github.com//pseudoical/apes-shaders/archive/refs/heads/main.zip
```

# Extract the shaders

```bash
node ./src/shaders.mjs
```

> Download the WASM file if needed and extract shaders.

```bash
node ./src/shaders.mjs --fetch
```

> Force download the WASM file and extract shaders.

---

<p align="center">This project is licensed under the <a href="LICENSE">WTFPL, Version 2</a>.</p>
