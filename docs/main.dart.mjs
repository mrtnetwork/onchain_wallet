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
            _1: (decoder, codeUnits) => decoder.decode(codeUnits),
      _2: () => new TextDecoder("utf-8", {fatal: true}),
      _3: () => new TextDecoder("utf-8", {fatal: false}),
      _4: (s) => +s,
      _5: x0 => new Uint8Array(x0),
      _6: (x0,x1,x2) => x0.set(x1,x2),
      _7: (x0,x1) => x0.transferFromImageBitmap(x1),
      _8: x0 => x0.arrayBuffer(),
      _9: (x0,x1,x2) => x0.slice(x1,x2),
      _10: (x0,x1) => x0.decode(x1),
      _11: (x0,x1) => x0.segment(x1),
      _12: () => new TextDecoder(),
      _14: x0 => x0.buffer,
      _15: x0 => x0.wasmMemory,
      _16: () => globalThis.window._flutter_skwasmInstance,
      _17: x0 => x0.rasterStartMilliseconds,
      _18: x0 => x0.rasterEndMilliseconds,
      _19: x0 => x0.imageBitmaps,
      _135: (x0,x1) => x0.appendChild(x1),
      _166: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _167: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _168: (x0,x1) => new OffscreenCanvas(x0,x1),
      _169: x0 => x0.remove(),
      _170: (x0,x1) => x0.append(x1),
      _172: x0 => x0.unlock(),
      _173: x0 => x0.getReader(),
      _174: (x0,x1) => x0.item(x1),
      _175: x0 => x0.next(),
      _176: x0 => x0.now(),
      _177: (x0,x1) => x0.revokeObjectURL(x1),
      _178: x0 => x0.close(),
      _179: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _180: x0 => new window.ImageDecoder(x0),
      _181: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      _182: (x0,x1) => x0.decode(x1),
      _183: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._183(f,arguments.length,x0) }),
      _184: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _186: (x0,x1) => x0.getModifierState(x1),
      _187: x0 => x0.preventDefault(),
      _188: x0 => x0.stopPropagation(),
      _189: (x0,x1) => x0.removeProperty(x1),
      _190: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._190(f,arguments.length,x0) }),
      _191: x0 => new window.FinalizationRegistry(x0),
      _192: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _194: (x0,x1) => x0.unregister(x1),
      _195: (x0,x1) => x0.prepend(x1),
      _196: x0 => new Intl.Locale(x0),
      _197: (x0,x1) => x0.observe(x1),
      _198: x0 => x0.disconnect(),
      _199: (x0,x1) => x0.getAttribute(x1),
      _200: (x0,x1) => x0.contains(x1),
      _201: (x0,x1) => x0.querySelector(x1),
      _202: (x0,x1) => x0.matchMedia(x1),
      _203: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._203(f,arguments.length,x0) }),
      _204: (x0,x1,x2) => x0.call(x1,x2),
      _205: x0 => x0.blur(),
      _206: x0 => x0.hasFocus(),
      _207: (x0,x1) => x0.removeAttribute(x1),
      _208: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _209: (x0,x1) => x0.hasAttribute(x1),
      _210: (x0,x1) => x0.getModifierState(x1),
      _211: (x0,x1) => x0.createTextNode(x1),
      _212: x0 => x0.getBoundingClientRect(),
      _213: (x0,x1) => x0.replaceWith(x1),
      _214: (x0,x1) => x0.contains(x1),
      _215: (x0,x1) => x0.closest(x1),
      _653: x0 => new Uint8Array(x0),
      _656: () => globalThis.window.flutterConfiguration,
      _658: x0 => x0.assetBase,
      _663: x0 => x0.canvasKitMaximumSurfaces,
      _664: x0 => x0.debugShowSemanticsNodes,
      _665: x0 => x0.hostElement,
      _666: x0 => x0.multiViewEnabled,
      _667: x0 => x0.nonce,
      _669: x0 => x0.fontFallbackBaseUrl,
      _679: x0 => x0.console,
      _680: x0 => x0.devicePixelRatio,
      _681: x0 => x0.document,
      _682: x0 => x0.history,
      _683: x0 => x0.innerHeight,
      _684: x0 => x0.innerWidth,
      _685: x0 => x0.location,
      _686: x0 => x0.navigator,
      _687: x0 => x0.visualViewport,
      _688: x0 => x0.performance,
      _689: x0 => x0.parent,
      _691: x0 => x0.URL,
      _693: (x0,x1) => x0.getComputedStyle(x1),
      _694: x0 => x0.screen,
      _695: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._695(f,arguments.length,x0) }),
      _696: (x0,x1) => x0.requestAnimationFrame(x1),
      _700: (x0,x1) => x0.warn(x1),
      _702: (x0,x1) => x0.debug(x1),
      _703: x0 => globalThis.parseFloat(x0),
      _704: () => globalThis.window,
      _705: () => globalThis.Intl,
      _706: () => globalThis.Symbol,
      _707: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _709: x0 => x0.clipboard,
      _710: x0 => x0.maxTouchPoints,
      _711: x0 => x0.vendor,
      _712: x0 => x0.language,
      _713: x0 => x0.platform,
      _714: x0 => x0.userAgent,
      _715: (x0,x1) => x0.vibrate(x1),
      _716: x0 => x0.languages,
      _717: x0 => x0.documentElement,
      _718: (x0,x1) => x0.querySelector(x1),
      _719: (x0,x1) => x0.querySelectorAll(x1),
      _721: (x0,x1) => x0.createElement(x1),
      _724: (x0,x1) => x0.createEvent(x1),
      _725: x0 => x0.activeElement,
      _728: x0 => x0.head,
      _729: x0 => x0.body,
      _731: (x0,x1) => { x0.title = x1 },
      _734: x0 => x0.visibilityState,
      _735: () => globalThis.document,
      _736: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._736(f,arguments.length,x0) }),
      _737: (x0,x1) => x0.dispatchEvent(x1),
      _745: x0 => x0.target,
      _747: x0 => x0.timeStamp,
      _748: x0 => x0.type,
      _750: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _757: x0 => x0.firstChild,
      _761: x0 => x0.parentElement,
      _763: (x0,x1) => { x0.textContent = x1 },
      _764: x0 => x0.parentNode,
      _765: x0 => x0.nextSibling,
      _766: (x0,x1) => x0.removeChild(x1),
      _767: x0 => x0.isConnected,
      _775: x0 => x0.clientHeight,
      _776: x0 => x0.clientWidth,
      _777: x0 => x0.offsetHeight,
      _778: x0 => x0.offsetWidth,
      _779: x0 => x0.id,
      _780: (x0,x1) => { x0.id = x1 },
      _783: (x0,x1) => { x0.spellcheck = x1 },
      _784: x0 => x0.tagName,
      _785: x0 => x0.style,
      _787: (x0,x1) => x0.querySelectorAll(x1),
      _788: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _789: x0 => x0.tabIndex,
      _790: (x0,x1) => { x0.tabIndex = x1 },
      _791: (x0,x1) => x0.focus(x1),
      _792: x0 => x0.scrollTop,
      _793: (x0,x1) => { x0.scrollTop = x1 },
      _794: (x0,x1) => { x0.scrollLeft = x1 },
      _795: x0 => x0.scrollLeft,
      _796: x0 => x0.classList,
      _797: (x0,x1) => x0.scrollIntoView(x1),
      _800: (x0,x1) => { x0.className = x1 },
      _802: (x0,x1) => x0.getElementsByClassName(x1),
      _803: x0 => x0.click(),
      _804: (x0,x1) => x0.attachShadow(x1),
      _807: x0 => x0.computedStyleMap(),
      _808: (x0,x1) => x0.get(x1),
      _814: (x0,x1) => x0.getPropertyValue(x1),
      _815: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _816: x0 => x0.offsetLeft,
      _817: x0 => x0.offsetTop,
      _818: x0 => x0.offsetParent,
      _820: (x0,x1) => { x0.name = x1 },
      _821: x0 => x0.content,
      _822: (x0,x1) => { x0.content = x1 },
      _826: (x0,x1) => { x0.src = x1 },
      _827: x0 => x0.naturalWidth,
      _828: x0 => x0.naturalHeight,
      _832: (x0,x1) => { x0.crossOrigin = x1 },
      _834: (x0,x1) => { x0.decoding = x1 },
      _835: x0 => x0.decode(),
      _840: (x0,x1) => { x0.nonce = x1 },
      _845: (x0,x1) => { x0.width = x1 },
      _847: (x0,x1) => { x0.height = x1 },
      _850: (x0,x1) => x0.getContext(x1),
      _918: x0 => x0.width,
      _919: x0 => x0.height,
      _921: (x0,x1) => x0.fetch(x1),
      _922: x0 => x0.status,
      _924: x0 => x0.body,
      _925: x0 => x0.arrayBuffer(),
      _928: x0 => x0.read(),
      _929: x0 => x0.value,
      _930: x0 => x0.done,
      _937: x0 => x0.name,
      _938: x0 => x0.x,
      _939: x0 => x0.y,
      _942: x0 => x0.top,
      _943: x0 => x0.right,
      _944: x0 => x0.bottom,
      _945: x0 => x0.left,
      _955: x0 => x0.height,
      _956: x0 => x0.width,
      _957: x0 => x0.scale,
      _958: (x0,x1) => { x0.value = x1 },
      _961: (x0,x1) => { x0.placeholder = x1 },
      _963: (x0,x1) => { x0.name = x1 },
      _964: x0 => x0.selectionDirection,
      _965: x0 => x0.selectionStart,
      _966: x0 => x0.selectionEnd,
      _969: x0 => x0.value,
      _971: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _972: x0 => x0.readText(),
      _973: (x0,x1) => x0.writeText(x1),
      _975: x0 => x0.altKey,
      _976: x0 => x0.code,
      _977: x0 => x0.ctrlKey,
      _978: x0 => x0.key,
      _979: x0 => x0.keyCode,
      _980: x0 => x0.location,
      _981: x0 => x0.metaKey,
      _982: x0 => x0.repeat,
      _983: x0 => x0.shiftKey,
      _984: x0 => x0.isComposing,
      _986: x0 => x0.state,
      _987: (x0,x1) => x0.go(x1),
      _989: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _990: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _991: x0 => x0.pathname,
      _992: x0 => x0.search,
      _993: x0 => x0.hash,
      _997: x0 => x0.state,
      _1000: (x0,x1) => x0.createObjectURL(x1),
      _1002: x0 => new Blob(x0),
      _1012: x0 => x0.matches,
      _1016: x0 => x0.matches,
      _1020: x0 => x0.relatedTarget,
      _1022: x0 => x0.clientX,
      _1023: x0 => x0.clientY,
      _1024: x0 => x0.offsetX,
      _1025: x0 => x0.offsetY,
      _1028: x0 => x0.button,
      _1029: x0 => x0.buttons,
      _1030: x0 => x0.ctrlKey,
      _1034: x0 => x0.pointerId,
      _1035: x0 => x0.pointerType,
      _1036: x0 => x0.pressure,
      _1037: x0 => x0.tiltX,
      _1038: x0 => x0.tiltY,
      _1039: x0 => x0.getCoalescedEvents(),
      _1042: x0 => x0.deltaX,
      _1043: x0 => x0.deltaY,
      _1044: x0 => x0.wheelDeltaX,
      _1045: x0 => x0.wheelDeltaY,
      _1046: x0 => x0.deltaMode,
      _1053: x0 => x0.changedTouches,
      _1056: x0 => x0.clientX,
      _1057: x0 => x0.clientY,
      _1060: x0 => x0.data,
      _1063: (x0,x1) => { x0.disabled = x1 },
      _1065: (x0,x1) => { x0.type = x1 },
      _1066: (x0,x1) => { x0.max = x1 },
      _1067: (x0,x1) => { x0.min = x1 },
      _1068: x0 => x0.value,
      _1069: (x0,x1) => { x0.value = x1 },
      _1070: x0 => x0.disabled,
      _1071: (x0,x1) => { x0.disabled = x1 },
      _1073: (x0,x1) => { x0.placeholder = x1 },
      _1075: (x0,x1) => { x0.name = x1 },
      _1076: (x0,x1) => { x0.autocomplete = x1 },
      _1078: x0 => x0.selectionDirection,
      _1079: x0 => x0.selectionStart,
      _1081: x0 => x0.selectionEnd,
      _1084: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1085: (x0,x1) => x0.add(x1),
      _1087: (x0,x1) => { x0.noValidate = x1 },
      _1088: (x0,x1) => { x0.method = x1 },
      _1089: (x0,x1) => { x0.action = x1 },
      _1095: (x0,x1) => x0.getContext(x1),
      _1097: x0 => x0.convertToBlob(),
      _1114: x0 => x0.orientation,
      _1115: x0 => x0.width,
      _1116: x0 => x0.height,
      _1117: (x0,x1) => x0.lock(x1),
      _1136: x0 => new ResizeObserver(x0),
      _1139: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1139(f,arguments.length,x0,x1) }),
      _1147: x0 => x0.length,
      _1148: x0 => x0.iterator,
      _1149: x0 => x0.Segmenter,
      _1150: x0 => x0.v8BreakIterator,
      _1151: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1154: x0 => x0.language,
      _1155: x0 => x0.script,
      _1156: x0 => x0.region,
      _1174: x0 => x0.done,
      _1175: x0 => x0.value,
      _1176: x0 => x0.index,
      _1180: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1181: (x0,x1) => x0.adoptText(x1),
      _1182: x0 => x0.first(),
      _1183: x0 => x0.next(),
      _1184: x0 => x0.current(),
      _1186: () => globalThis.window.FinalizationRegistry,
      _1197: x0 => x0.hostElement,
      _1198: x0 => x0.viewConstraints,
      _1201: x0 => x0.maxHeight,
      _1202: x0 => x0.maxWidth,
      _1203: x0 => x0.minHeight,
      _1204: x0 => x0.minWidth,
      _1205: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1205(f,arguments.length,x0) }),
      _1206: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1206(f,arguments.length,x0) }),
      _1207: (x0,x1) => ({addView: x0,removeView: x1}),
      _1210: x0 => x0.loader,
      _1211: () => globalThis._flutter,
      _1212: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1213: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1213(f,arguments.length,x0) }),
      _1214: (module,f) => finalizeWrapper(f, function() { return module.exports._1214(f,arguments.length) }),
      _1215: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1218: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1218(f,arguments.length,x0) }),
      _1219: x0 => ({runApp: x0}),
      _1221: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1221(f,arguments.length,x0,x1) }),
      _1222: x0 => new Promise(x0),
      _1223: x0 => x0.length,
      _1224: () => globalThis.window.ImageDecoder,
      _1225: x0 => x0.tracks,
      _1227: x0 => x0.completed,
      _1229: x0 => x0.image,
      _1235: x0 => x0.displayWidth,
      _1236: x0 => x0.displayHeight,
      _1237: x0 => x0.duration,
      _1240: x0 => x0.ready,
      _1241: x0 => x0.selectedTrack,
      _1242: x0 => x0.repetitionCount,
      _1243: x0 => x0.frameCount,
      _1285: x0 => new BarcodeDetector(x0),
      _1287: (x0,x1) => x0.addListener(x1),
      _1293: (x0,x1) => x0.getURL(x1),
      _1294: (x0,x1) => x0.postMessage(x1),
      _1295: x0 => x0.close(),
      _1296: (x0,x1) => x0.postMessage(x1),
      _1299: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1299(f,arguments.length,x0,x1,x2) }),
      _1300: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1300(f,arguments.length,x0) }),
      _1301: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1301(f,arguments.length,x0) }),
      _1302: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1302(f,arguments.length,x0,x1,x2) }),
      _1303: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1303(f,arguments.length,x0) }),
      _1304: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1304(f,arguments.length,x0) }),
      _1305: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1305(f,arguments.length,x0) }),
      _1306: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1306(f,arguments.length,x0,x1) }),
      _1326: Date.now,
      _1328: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1329: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1330: () => typeof dartUseDateNowForTicks !== "undefined",
      _1331: () => 1000 * performance.now(),
      _1332: () => Date.now(),
      _1335: () => new WeakMap(),
      _1336: (map, o) => map.get(o),
      _1337: (map, o, v) => map.set(o, v),
      _1338: x0 => new WeakRef(x0),
      _1339: x0 => x0.deref(),
      _1346: () => globalThis.WeakRef,
      _1350: s => JSON.stringify(s),
      _1351: s => printToConsole(s),
      _1352: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      _1353: (o, p, r) => o.replaceAll(p, () => r),
      _1354: (o, p, r) => o.replace(p, () => r),
      _1355: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1356: s => s.toUpperCase(),
      _1357: s => s.trim(),
      _1358: s => s.trimLeft(),
      _1359: s => s.trimRight(),
      _1360: (string, times) => string.repeat(times),
      _1361: Function.prototype.call.bind(String.prototype.indexOf),
      _1362: (s, p, i) => s.lastIndexOf(p, i),
      _1363: (string, token) => string.split(token),
      _1364: Object.is,
      _1368: (o, t) => typeof o === t,
      _1369: (o, c) => o instanceof c,
      _1370: o => Object.keys(o),
      _1403: (x0,x1) => x0.call(x1),
      _1424: x0 => new Array(x0),
      _1426: x0 => x0.length,
      _1428: (x0,x1) => x0[x1],
      _1429: (x0,x1,x2) => { x0[x1] = x2 },
      _1432: (x0,x1,x2) => new DataView(x0,x1,x2),
      _1434: x0 => new Int8Array(x0),
      _1435: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _1437: x0 => new Uint8ClampedArray(x0),
      _1439: x0 => new Int16Array(x0),
      _1441: x0 => new Uint16Array(x0),
      _1443: x0 => new Int32Array(x0),
      _1445: x0 => new Uint32Array(x0),
      _1447: x0 => new Float32Array(x0),
      _1449: x0 => new Float64Array(x0),
      _1473: x0 => x0.random(),
      _1474: (x0,x1) => x0.getRandomValues(x1),
      _1475: () => globalThis.crypto,
      _1476: () => globalThis.Math,
      _1486: x0 => ({worker_message_closed: x0}),
      _1489: () => ({}),
      _1490: (x0,x1) => new Worker(x0,x1),
      _1491: x0 => x0.terminate(),
      _1492: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1492(f,arguments.length,x0) }),
      _1493: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1493(f,arguments.length,x0) }),
      _1494: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1495: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1495(f,arguments.length,x0) }),
      _1496: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1496(f,arguments.length,x0) }),
      _1497: (x0,x1) => x0.postMessage(x1),
      _1498: (x0,x1,x2,x3,x4,x5) => ({worker_message_message: x0,worker_message_buffer: x1,worker_message_port: x2,worker_config: x3,worker_message_type: x4,worker_message_id: x5}),
      _1503: x0 => x0.worker_message_type,
      _1504: x0 => x0.worker_message_id,
      _1505: x0 => x0.worker_message_closed,
      _1506: x0 => x0.worker_message_message,
      _1507: x0 => x0.worker_message_buffer,
      _1508: x0 => x0.worker_message_port,
      _1509: x0 => x0.worker_config,
      _1510: x0 => ({type: x0}),
      _1511: (x0,x1,x2) => new File(x0,x1,x2),
      _1555: x0 => x0.arrayBuffer(),
      _1556: () => new AbortController(),
      _1557: x0 => x0.getReader(),
      _1558: x0 => x0.cancel(),
      _1559: x0 => x0.abort(),
      _1560: x0 => x0.read(),
      _1561: x0 => x0.releaseLock(),
      _1562: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1562(f,arguments.length,x0,x1,x2) }),
      _1563: (x0,x1) => x0.forEach(x1),
      _1564: (module,f) => finalizeWrapper(f, function() { return module.exports._1564(f,arguments.length) }),
      _1565: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1565(f,arguments.length,x0) }),
      _1566: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1566(f,arguments.length,x0) }),
      _1567: (x0,x1,x2) => x0.close(x1,x2),
      _1568: () => new Headers(),
      _1569: (x0,x1,x2) => x0.append(x1,x2),
      _1570: (x0,x1,x2,x3) => ({method: x0,headers: x1,body: x2,signal: x3}),
      _1571: (x0,x1,x2) => x0.fetch(x1,x2),
      _1572: (x0,x1) => globalThis.fetch(x0,x1),
      _1574: () => globalThis.window,
      _1636: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1637: x0 => x0.getPublicKey(),
      _1721: (x0,x1) => x0.get(x1),
      _1722: (x0,x1) => x0.query(x1),
      _1724: (x0,x1,x2) => x0.create(x1,x2),
      _1725: (x0,x1,x2,x3) => x0.update(x1,x2,x3),
      _1726: (x0,x1,x2,x3) => x0.sendMessage(x1,x2,x3),
      _1727: x0 => x0.onActivated,
      _1728: x0 => x0.onUpdated,
      _1729: x0 => x0.onRemoved,
      _1730: (x0,x1,x2,x3,x4,x5,x6) => ({active: x0,autoDiscardable: x1,highlighted: x2,muted: x3,openerTabId: x4,pinned: x5,url: x6}),
      _1731: (x0,x1,x2,x3,x4,x5) => ({active: x0,index: x1,openerTabId: x2,pinned: x3,url: x4,windowId: x5}),
      _1732: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11) => ({active: x0,audible: x1,autoDiscardable: x2,currentWindow: x3,discarded: x4,highlighted: x5,index: x6,lastFocusedWindow: x7,muted: x8,pinned: x9,windowId: x10,url: x11}),
      _1734: x0 => x0.active,
      _1742: x0 => x0.favIconUrl,
      _1748: x0 => x0.id,
      _1756: x0 => x0.title,
      _1758: x0 => x0.url,
      _1760: x0 => x0.windowId,
      _1777: x0 => x0.tabId,
      _1778: x0 => x0.windowId,
      _1789: x0 => x0.status,
      _1812: (x0,x1) => x0.create(x1),
      _1813: (x0,x1) => x0.getCurrent(x1),
      _1815: (x0,x1,x2) => x0.get(x1,x2),
      _1816: x0 => x0.onFocusChanged,
      _1818: (x0,x1) => x0.getAll(x1),
      _1819: (x0,x1,x2) => x0.update(x1,x2),
      _1820: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => ({focused: x0,height: x1,incognito: x2,left: x3,tabId: x4,top: x5,url: x6,width: x7,type: x8}),
      _1821: (x0,x1,x2,x3,x4,x5,x6) => ({drawAttention: x0,focused: x1,height: x2,left: x3,state: x4,top: x5,width: x6}),
      _1822: (x0,x1) => ({populate: x0,windowTypes: x1}),
      _1836: x0 => x0.focused,
      _1838: x0 => x0.id,
      _1840: x0 => x0.left,
      _1843: x0 => x0.tabs,
      _1844: x0 => x0.top,
      _1849: x0 => x0.storage,
      _1850: x0 => x0.tabs,
      _1851: x0 => x0.runtime,
      _1853: x0 => x0.windows,
      _1854: x0 => x0.sidePanel,
      _1855: x0 => x0.sidePanel,
      _1857: x0 => x0.sidebarAction,
      _1858: x0 => x0.sidebarAction,
      _1859: x0 => x0.runtime,
      _1862: () => globalThis.chrome,
      _1863: () => globalThis.chrome,
      _1864: () => globalThis.browser,
      _1865: () => globalThis.browser,
      _1866: () => globalThis.opr,
      _1871: () => globalThis.window,
      _1873: x0 => x0.parent,
      _1874: x0 => x0.BarcodeDetector,
      _1875: x0 => x0.navigator,
      _1876: x0 => x0.navigator,
      _1878: x0 => x0.document,
      _1879: x0 => x0.document,
      _1880: x0 => x0.location,
      _1883: x0 => x0.focus(),
      _1890: x0 => x0.href,
      _1892: x0 => x0.hostname,
      _1895: x0 => x0.search,
      _1897: (x0,x1) => x0.createElement(x1),
      _1898: x0 => x0.body,
      _1900: x0 => x0.hasFocus(),
      _1902: (x0,x1) => x0.appendChild(x1),
      _1903: x0 => x0.click(),
      _1904: (x0,x1) => x0.removeChild(x1),
      _1905: x0 => globalThis.URL.createObjectURL(x0),
      _1906: (x0,x1) => x0.item(x1),
      _1907: (module,f) => finalizeWrapper(f, function() { return module.exports._1907(f,arguments.length) }),
      _1908: (module,f) => finalizeWrapper(f, function() { return module.exports._1908(f,arguments.length) }),
      _1909: (module,f) => finalizeWrapper(f, function() { return module.exports._1909(f,arguments.length) }),
      _1911: (x0,x1) => x0.writeText(x1),
      _1912: x0 => x0.readText(),
      _1914: x0 => x0.mediaDevices,
      _1916: x0 => x0.onLine,
      _1917: x0 => x0.credentials,
      _1918: (x0,x1,x2,x3,x4) => x0.share(x1,x2,x3,x4),
      _1919: x0 => x0.clipboard,
      _1921: (x0,x1) => x0.getUserMedia(x1),
      _1922: (x0,x1) => x0.detect(x1),
      _1926: x0 => x0.rawValue,
      _1934: x0 => x0.name,
      _1936: x0 => x0.arrayBuffer(),
      _1937: x0 => x0.text(),
      _1939: x0 => x0.length,
      _1945: x0 => x0.done,
      _1946: x0 => x0.value,
      _1947: x0 => x0.ok,
      _1948: x0 => x0.status,
      _1949: x0 => x0.headers,
      _1950: x0 => x0.body,
      _1951: x0 => x0.text(),
      _1954: (x0,x1) => { x0.onerror = x1 },
      _1955: (x0,x1) => { x0.onmessage = x1 },
      _1977: x0 => x0.data,
      _1978: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1979: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _1981: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1981(f,arguments.length,x0) }),
      _2005: x0 => x0.message,
      _2006: x0 => x0.signal,
      _2007: x0 => x0.aborted,
      _2008: (x0,x1) => new WebSocket(x0,x1),
      _2009: x0 => x0.readyState,
      _2011: (x0,x1) => x0.send(x1),
      _2013: (x0,x1) => { x0.onclose = x1 },
      _2014: (x0,x1) => { x0.onmessage = x1 },
      _2015: (x0,x1) => { x0.onopen = x1 },
      _2016: x0 => x0.code,
      _2017: x0 => x0.reason,
      _2019: x0 => x0.data,
      _2028: x0 => x0.close,
      _2034: x0 => x0.id,
      _2035: (x0,x1) => { x0.id = x1 },
      _2040: (x0,x1) => { x0.autoplay = x1 },
      _2045: (x0,x1) => { x0.href = x1 },
      _2046: (x0,x1) => { x0.target = x1 },
      _2047: (x0,x1) => { x0.download = x1 },
      _2050: (x0,x1) => { x0.srcObject = x1 },
      _2059: (x0,x1) => { x0.accept = x1 },
      _2061: (x0,x1) => { x0.type = x1 },
      _2062: (x0,x1) => { x0.onchange = x1 },
      _2063: (x0,x1) => { x0.onerror = x1 },
      _2064: (x0,x1) => { x0.oncancel = x1 },
      _2065: x0 => x0.files,
      _2069: (x0,x1) => ({type: x0,alg: x1}),
      _2070: (x0,x1) => ({id: x0,name: x1}),
      _2071: (x0,x1,x2) => ({id: x0,displayName: x1,name: x2}),
      _2072: x0 => x0.id,
      _2073: x0 => x0.type,
      _2074: () => globalThis.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable(),
      _2077: x0 => x0.response,
      _2079: x0 => x0.clientDataJSON,
      _2080: x0 => x0.authenticatorData,
      _2081: x0 => x0.signature,
      _2085: x0 => x0.getPublicKeyAlgorithm(),
      _2087: (x0,x1) => x0.create(x1),
      _2088: (x0,x1) => x0.get(x1),
      _2089: x0 => ({authenticatorAttachment: x0}),
      _2090: (x0,x1,x2,x3,x4) => ({authenticatorSelection: x0,challenge: x1,pubKeyCredParams: x2,rp: x3,user: x4}),
      _2091: x0 => ({publicKey: x0}),
      _2092: (x0,x1) => ({id: x0,type: x1}),
      _2093: (x0,x1,x2) => ({challenge: x0,allowCredentials: x1,userVerification: x2}),
      _2094: (x0,x1) => ({publicKey: x0,mediation: x1}),
      _2101: (x0,x1,x2,x3) => x0.sendMessage(x1,x2,x3),
      _2105: x0 => x0.id,
      _2107: x0 => x0.onMessage,
      _2109: x0 => x0.onConnect,
      _2116: x0 => x0.tab,
      _2121: x0 => x0.onDisconnect,
      _2122: x0 => x0.onMessage,
      _2141: (x0,x1,x2,x3,x4) => ({data: x0,type: x1,additional: x2,platform: x3,target: x4}),
      _2142: x0 => x0.target,
      _2143: x0 => x0.type,
      _2144: (x0,x1) => { x0.client_id = x1 },
      _2145: x0 => x0.client_id,
      _2146: (x0,x1) => { x0.request_id = x1 },
      _2147: x0 => x0.request_id,
      _2148: x0 => x0.platform,
      _2149: x0 => x0.data,
      _2150: x0 => x0.additional,
      _2164: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _2165: (handle) => clearTimeout(handle),
      _2166: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _2167: (handle) => clearInterval(handle),
      _2168: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _2169: () => Date.now(),
      _2170: () => new Error().stack,
      _2171: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _2172: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _2173: (x0,x1) => x0.exec(x1),
      _2174: (x0,x1) => x0.test(x1),
      _2177: o => o === undefined,
      _2179: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _2181: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _2182: o => o instanceof RegExp,
      _2183: (l, r) => l === r,
      _2184: o => o,
      _2185: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      _2186: o => o,
      _2187: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      _2188: o => o,
      _2189: b => !!b,
      _2190: o => o.length,
      _2192: (o, i) => o[i],
      _2193: f => f.dartFunction,
      _2194: () => ({}),
      _2195: () => [],
      _2197: () => globalThis,
      _2198: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _2200: (o, p) => o[p],
      _2201: (o, p, v) => o[p] = v,
      _2202: (o, m, a) => o[m].apply(o, a),
      _2204: o => String(o),
      _2205: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _2206: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2206(f,arguments.length,x0) }),
      _2207: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2207(f,arguments.length,x0,x1) }),
      _2208: o => {
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
      _2209: o => [o],
      _2210: (o0, o1) => [o0, o1],
      _2211: (o0, o1, o2) => [o0, o1, o2],
      _2212: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _2213: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      _2214: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2215: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2216: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2217: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2218: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2219: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2220: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2221: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2222: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2223: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2224: x0 => new ArrayBuffer(x0),
      _2225: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _2227: x0 => x0.index,
      _2229: x0 => x0.flags,
      _2230: x0 => x0.multiline,
      _2231: x0 => x0.ignoreCase,
      _2232: x0 => x0.unicode,
      _2233: x0 => x0.dotAll,
      _2234: (x0,x1) => { x0.lastIndex = x1 },
      _2235: (o, p) => p in o,
      _2236: (o, p) => o[p],
      _2239: o => o instanceof Array,
      _2240: (a, i) => a.splice(i, 1)[0],
      _2242: (a, l) => a.length = l,
      _2243: a => a.pop(),
      _2244: (a, i) => a.splice(i, 1),
      _2245: (a, s) => a.join(s),
      _2246: (a, s, e) => a.slice(s, e),
      _2248: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _2249: a => a.length,
      _2250: (a, l) => a.length = l,
      _2251: (a, i) => a[i],
      _2252: (a, i, v) => a[i] = v,
      _2254: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      _2255: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _2257: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      _2258: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _2259: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      _2260: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _2261: o => o instanceof Uint8ClampedArray,
      _2262: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _2263: o => o instanceof Uint16Array,
      _2264: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _2265: o => o instanceof Int16Array,
      _2266: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _2267: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      _2268: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _2269: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      _2270: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _2272: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _2273: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      _2274: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _2275: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      _2276: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _2277: (a, i) => a.push(i),
      _2278: (t, s) => t.set(s),
      _2279: l => new DataView(new ArrayBuffer(l)),
      _2280: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _2282: o => o.buffer,
      _2283: o => o.byteOffset,
      _2284: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _2285: (b, o) => new DataView(b, o),
      _2286: (b, o, l) => new DataView(b, o, l),
      _2287: Function.prototype.call.bind(DataView.prototype.getUint8),
      _2288: Function.prototype.call.bind(DataView.prototype.setUint8),
      _2289: Function.prototype.call.bind(DataView.prototype.getInt8),
      _2290: Function.prototype.call.bind(DataView.prototype.setInt8),
      _2291: Function.prototype.call.bind(DataView.prototype.getUint16),
      _2292: Function.prototype.call.bind(DataView.prototype.setUint16),
      _2293: Function.prototype.call.bind(DataView.prototype.getInt16),
      _2294: Function.prototype.call.bind(DataView.prototype.setInt16),
      _2295: Function.prototype.call.bind(DataView.prototype.getUint32),
      _2296: Function.prototype.call.bind(DataView.prototype.setUint32),
      _2297: Function.prototype.call.bind(DataView.prototype.getInt32),
      _2298: Function.prototype.call.bind(DataView.prototype.setInt32),
      _2301: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _2302: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _2303: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _2304: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _2305: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _2306: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _2307: Function.prototype.call.bind(Number.prototype.toString),
      _2308: Function.prototype.call.bind(BigInt.prototype.toString),
      _2309: Function.prototype.call.bind(Number.prototype.toString),
      _2310: (d, digits) => d.toFixed(digits),
      _2342: x0 => x0.ok,
      _2343: x0 => x0.err,
      _2344: x0 => x0.ok,
      _2345: x0 => x0.err,
      _2348: x0 => new Uint8Array(x0),
      _2350: x0 => globalThis.Uint8Array.from(x0),
      _2352: x0 => x0.buffer,
      _2353: () => new Uint8Array(),
      _2357: x0 => x0.session,
      _2366: (x0,x1) => x0.get(x1),
      _2370: (x0,x1) => x0.remove(x1),
      _2374: (x0,x1) => x0.set(x1),
      _2385: x0 => x0.open,
      _2386: (x0,x1) => x0.open(x1),
      _2390: (x0,x1) => ({tabId: x0,windowId: x1}),
      _2393: x0 => x0.open,
      _2394: x0 => x0.open(),
      _2395: x0 => x0.close(),
      _2403: x0 => x0.stop(),
      _2405: x0 => x0.getTracks(),
      _2413: () => globalThis.console,
      _2452: (x0,x1) => x0.error(x1),

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
