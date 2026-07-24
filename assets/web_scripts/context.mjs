// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `load-ids` option is passed. Each load ID maps to one
  //   or more wasm files as specified in the emitted JSON file. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It also takes a callback that should be invoked with the
  //   loaded module in a format supported by `WebAssembly.compile` or
  //   `WebAssembly.compileStreaming` and the result of using the JS 'import'
  //   API on the js file path. It should return a Promise that resolves when
  //   all the modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports,
      {loadDeferredModules, loadDynamicModule, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _4: (s) => +s,
      _5: Date.now,
      _7: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _8: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _29: s => JSON.stringify(s),
      _30: s => printToConsole(s),
      _31: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      _32: (o, p, r) => o.replaceAll(p, () => r),
      _33: (o, p, r) => o.replace(p, () => r),
      _34: Function.prototype.call.bind(String.prototype.toLowerCase),
      _35: s => s.toUpperCase(),
      _36: s => s.trim(),
      _39: (string, times) => string.repeat(times),
      _40: Function.prototype.call.bind(String.prototype.indexOf),
      _41: (s, p, i) => s.lastIndexOf(p, i),
      _42: (string, token) => string.split(token),
      _43: Object.is,
      _47: (o, t) => typeof o === t,
      _48: (o, c) => o instanceof c,
      _49: o => Object.keys(o),
      _52: (o,s,v) => o[s] = v,
      _72: (m) => import(m),
      _82: (x0,x1) => x0.call(x1),
      _104: x0 => new Array(x0),
      _105: x0 => globalThis.Array.from(x0),
      _106: x0 => x0.length,
      _108: (x0,x1) => x0[x1],
      _109: (x0,x1,x2) => { x0[x1] = x2 },
      _111: x0 => new Promise(x0),
      _113: (x0,x1,x2) => new DataView(x0,x1,x2),
      _115: x0 => new Int8Array(x0),
      _116: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _117: x0 => new Uint8Array(x0),
      _119: x0 => new Uint8ClampedArray(x0),
      _121: x0 => new Int16Array(x0),
      _123: x0 => new Uint16Array(x0),
      _125: x0 => new Int32Array(x0),
      _127: x0 => new Uint32Array(x0),
      _129: x0 => new Float32Array(x0),
      _131: x0 => new Float64Array(x0),
      _151: (x0,x1,x2) => x0.call(x1,x2),
      _152: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._152(f,arguments.length,x0,x1) }),
      _153: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._153(f,arguments.length,x0,x1) }),
      _155: () => Symbol("jsBoxedDartObjectProperty"),
      _156: x0 => x0.random(),
      _157: (x0,x1) => x0.getRandomValues(x1),
      _158: () => globalThis.crypto,
      _159: () => globalThis.Math,
      _160: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._160(f,arguments.length,x0) }),
      _161: (module,f) => finalizeWrapper(f, function() { return module.exports._161(f,arguments.length) }),
      _162: () => new MessageChannel(),
      _163: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._163(f,arguments.length,x0) }),
      _164: x0 => x0.start(),
      _165: x0 => { globalThis.init_script = x0 },
      _166: x0 => { globalThis.onscriptmessage = x0 },
      _167: x0 => { globalThis.close_script = x0 },
      _168: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._168(f,arguments.length,x0) }),
      _169: (x0,x1,x2) => x0.postMessage(x1,x2),
      _194: x0 => ({type: x0}),
      _195: (x0,x1,x2) => new File(x0,x1,x2),
      _196: (x0,x1,x2,x3,x4,x5) => ({worker_message_message: x0,worker_message_buffer: x1,worker_message_port: x2,worker_config: x3,worker_message_type: x4,worker_message_id: x5}),
      _197: (x0,x1) => ({transfableParams: x0,message: x1}),
      _200: (x0,x1,x2) => ({worker_message_buffer: x0,worker_message_type: x1,worker_message_id: x2}),
      _201: x0 => x0.worker_message_type,
      _202: x0 => x0.worker_message_id,
      _204: x0 => x0.worker_message_message,
      _205: x0 => x0.worker_message_buffer,
      _206: x0 => x0.worker_message_port,
      _207: x0 => x0.worker_config,
      _247: x0 => x0.arrayBuffer(),
      _248: () => new AbortController(),
      _249: x0 => x0.getReader(),
      _250: x0 => x0.cancel(),
      _251: x0 => x0.abort(),
      _252: x0 => x0.read(),
      _253: x0 => x0.releaseLock(),
      _254: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._254(f,arguments.length,x0,x1,x2) }),
      _255: (x0,x1) => x0.forEach(x1),
      _256: (module,f) => finalizeWrapper(f, function() { return module.exports._256(f,arguments.length) }),
      _257: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._257(f,arguments.length,x0) }),
      _258: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._258(f,arguments.length,x0) }),
      _259: (x0,x1,x2) => x0.close(x1,x2),
      _260: () => new Headers(),
      _261: (x0,x1,x2) => x0.append(x1,x2),
      _262: (x0,x1,x2,x3) => ({method: x0,headers: x1,body: x2,signal: x3}),
      _263: (x0,x1,x2) => x0.fetch(x1,x2),
      _264: (x0,x1) => globalThis.fetch(x0,x1),
      _266: () => globalThis.window,
      _277: (x0,x1) => x0.put(x1),
      _278: (x0,x1,x2) => x0.transaction(x1,x2),
      _279: (x0,x1) => x0.objectStore(x1),
      _280: (x0,x1) => x0.open(x1),
      _282: (x0,x1) => ({keyPath: x0,autoIncrement: x1}),
      _283: (x0,x1,x2) => x0.createObjectStore(x1,x2),
      _287: x0 => x0.close(),
      _293: (x0,x1) => x0.index(x1),
      _294: (x0,x1) => x0.get(x1),
      _295: (x0,x1) => x0.delete(x1),
      _296: x0 => globalThis.IDBKeyRange.only(x0),
      _297: (x0,x1,x2) => x0.openCursor(x1,x2),
      _298: (x0,x1,x2) => x0.openCursor(x1,x2),
      _299: (module,f) => finalizeWrapper(f, function() { return module.exports._299(f,arguments.length) }),
      _300: (x0,x1) => x0.advance(x1),
      _301: x0 => x0.continue(),
      _302: x0 => x0.delete(),
      _303: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._303(f,arguments.length,x0) }),
      _304: (x0,x1) => x0.add(x1),
      _305: x0 => ({unique: x0}),
      _306: (x0,x1,x2,x3) => x0.createIndex(x1,x2,x3),
      _307: x0 => x0.id,
      _309: x0 => x0.storage,
      _310: (x0,x1) => { x0.storage = x1 },
      _311: x0 => x0.storage_id,
      _312: (x0,x1) => { x0.storage_id = x1 },
      _313: x0 => x0.key,
      _314: (x0,x1) => { x0.key = x1 },
      _315: x0 => x0.key_a,
      _316: (x0,x1) => { x0.key_a = x1 },
      _317: x0 => x0.data,
      _318: (x0,x1) => { x0.data = x1 },
      _319: x0 => x0.createdAt,
      _320: (x0,x1) => { x0.createdAt = x1 },
      _321: x0 => x0.updateAt,
      _322: (x0,x1) => { x0.updateAt = x1 },
      _323: (x0,x1,x2) => x0.open(x1,x2),
      _324: (x0,x1) => x0.deleteObjectStore(x1),
      _325: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._325(f,arguments.length,x0) }),
      _326: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._326(f,arguments.length,x0) }),
      _327: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._327(f,arguments.length,x0) }),
      _551: x0 => x0.name,
      _553: x0 => x0.arrayBuffer(),
      _562: x0 => x0.done,
      _563: x0 => x0.value,
      _565: x0 => x0.status,
      _566: x0 => x0.headers,
      _567: x0 => x0.body,
      _586: x0 => x0.target,
      _594: x0 => x0.data,
      _623: x0 => x0.signal,
      _624: x0 => x0.aborted,
      _627: (x0,x1) => { x0.onmessage = x1 },
      _629: x0 => x0.port1,
      _630: x0 => x0.port2,
      _631: x0 => x0.close,
      _701: (x0,x1) => new WebSocket(x0,x1),
      _702: x0 => x0.readyState,
      _704: (x0,x1) => x0.send(x1),
      _706: (x0,x1) => { x0.onclose = x1 },
      _707: (x0,x1) => { x0.onmessage = x1 },
      _708: (x0,x1) => { x0.onopen = x1 },
      _709: x0 => x0.code,
      _710: x0 => x0.reason,
      _712: x0 => x0.data,
      _757: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._757(f,arguments.length,x0) }),
      _758: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._758(f,arguments.length,x0) }),
      _759: (module,f) => finalizeWrapper(f, function() { return module.exports._759(f,arguments.length) }),
      _760: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._760(f,arguments.length,x0) }),
      _761: (module,f) => finalizeWrapper(f, function() { return module.exports._761(f,arguments.length) }),
      _762: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._762(f,arguments.length,x0) }),
      _763: () => globalThis.indexedDB,
      _768: x0 => x0.version,
      _770: x0 => x0.objectStoreNames,
      _772: (x0,x1) => { x0.onversionchange = x1 },
      _805: x0 => x0.result,
      _806: (x0,x1) => { x0.onerror = x1 },
      _807: (x0,x1) => { x0.onsuccess = x1 },
      _818: (x0,x1) => { x0.onblocked = x1 },
      _819: (x0,x1) => { x0.onupgradeneeded = x1 },
      _832: x0 => x0.value,
      _859: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _860: (handle) => clearTimeout(handle),
      _863: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _865: () => new Error().stack,
      _866: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _867: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _868: (x0,x1) => x0.exec(x1),
      _869: (x0,x1) => x0.test(x1),
      _872: o => o === undefined,
      _874: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _876: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _877: o => o instanceof RegExp,
      _878: (l, r) => l === r,
      _879: o => o,
      _880: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      _881: o => o,
      _882: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      _883: o => o,
      _884: b => !!b,
      _885: o => o.length,
      _887: (o, i) => o[i],
      _888: f => f.dartFunction,
      _889: () => ({}),
      _890: () => [],
      _892: () => globalThis,
      _893: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _895: (o, p) => o[p],
      _896: (o, p, v) => o[p] = v,
      _899: o => String(o),
      _900: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _901: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._901(f,arguments.length,x0) }),
      _902: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._902(f,arguments.length,x0,x1) }),
      _903: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _904: o => [o],
      _905: (o0, o1) => [o0, o1],
      _906: (o0, o1, o2) => [o0, o1, o2],
      _907: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _908: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      _909: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _911: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _913: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _915: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _917: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _919: x0 => new ArrayBuffer(x0),
      _920: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _922: x0 => x0.index,
      _924: x0 => x0.flags,
      _925: x0 => x0.multiline,
      _926: x0 => x0.ignoreCase,
      _927: x0 => x0.unicode,
      _928: x0 => x0.dotAll,
      _929: (x0,x1) => { x0.lastIndex = x1 },
      _931: (o, p) => o[p],
      _932: (o, p, v) => o[p] = v,
      _934: o => o instanceof Array,
      _939: (a, i) => a.splice(i, 1),
      _941: (a, s, e) => a.slice(s, e),
      _944: a => a.length,
      _946: (a, i) => a[i],
      _949: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      _950: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _952: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      _953: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _954: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      _955: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _956: o => o instanceof Uint8ClampedArray,
      _957: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _958: o => o instanceof Uint16Array,
      _959: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _960: o => o instanceof Int16Array,
      _961: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _962: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      _963: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _964: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      _965: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _968: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      _969: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _970: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      _971: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _972: (a, i) => a.push(i),
      _973: (t, s) => t.set(s),
      _974: l => new DataView(new ArrayBuffer(l)),
      _975: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _977: o => o.buffer,
      _978: o => o.byteOffset,
      _979: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _980: (b, o) => new DataView(b, o),
      _981: (b, o, l) => new DataView(b, o, l),
      _982: Function.prototype.call.bind(DataView.prototype.getUint8),
      _983: Function.prototype.call.bind(DataView.prototype.setUint8),
      _984: Function.prototype.call.bind(DataView.prototype.getInt8),
      _985: Function.prototype.call.bind(DataView.prototype.setInt8),
      _986: Function.prototype.call.bind(DataView.prototype.getUint16),
      _987: Function.prototype.call.bind(DataView.prototype.setUint16),
      _988: Function.prototype.call.bind(DataView.prototype.getInt16),
      _989: Function.prototype.call.bind(DataView.prototype.setInt16),
      _990: Function.prototype.call.bind(DataView.prototype.getUint32),
      _991: Function.prototype.call.bind(DataView.prototype.setUint32),
      _992: Function.prototype.call.bind(DataView.prototype.getInt32),
      _993: Function.prototype.call.bind(DataView.prototype.setInt32),
      _998: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _999: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _1000: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _1001: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _1002: Function.prototype.call.bind(Number.prototype.toString),
      _1003: Function.prototype.call.bind(BigInt.prototype.toString),
      _1004: Function.prototype.call.bind(Number.prototype.toString),
      _1009: (x0,x1) => x0.initSync(x1),
      _1010: (x0,x1) => x0.new_request(x1),
      _1011: (x0,x1) => x0.setup_sapling_spend_params_inner(x1),
      _1012: (x0,x1) => x0.setup_sapling_output_params_inner(x1),
      _1014: (x0,x1,x2) => x0.fetch(x1,x2),
      _1015: (x0,x1) => globalThis.fetch(x0,x1),
      _1017: () => globalThis.window,
      _1018: () => globalThis.fetch,
      _1021: x0 => x0.ok,
      _1022: x0 => x0.status,
      _1023: x0 => x0.arrayBuffer(),
      _1025: x0 => x0.initSync,
      _1026: x0 => x0.new_request,
      _1027: x0 => x0.setup_sapling_spend_params_inner,
      _1028: x0 => x0.setup_sapling_output_params_inner,
      _1029: x0 => x0.bytes,
      _1030: x0 => x0.code,
      _1041: x0 => ({err: x0}),
      _1042: x0 => ({ok: x0}),
      _1043: x0 => new Uint8Array(x0),
      _1045: x0 => globalThis.Uint8Array.from(x0),
      _1047: x0 => x0.buffer,
      _1048: () => new Uint8Array(),

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });
    dartInstance.exports.$setThisModule(dartInstance);

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
