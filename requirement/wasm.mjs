let _wasmInstance;
let _inited = false;
self.addEventListener('message', async (event) => {
    if (_inited) {
        cryptoJsHandler(event.data);
        return;
    }
    let module;
    console.log(event.data.isHttp)
    if (event.data.module === null) {
        if (event.data.isHttp) {
            module = await import("./http.js");
        } else if (event.data.isStream) {
            module = await import("./stream_crypto.mjs");
        } else {
            module = await import("./crypto.mjs");
        }


    } else {
        const encodedModule = encodeURIComponent(event.data.module);
        module = await import(`data:text/javascript,${encodedModule}`);

    }
    if (event.data.isWasm) {
        const wasm = await WebAssembly.compile(event.data.wasm);
        _wasmInstance = await module.instantiate(wasm);
        module.invoke(_wasmInstance)
    }

    _inited = true;
    const data = cryptoJsActivation();
    self.postMessage(data);

});