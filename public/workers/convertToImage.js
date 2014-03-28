importScripts('/workers/jpegencoder.js');

self.addEventListener('message', function(e) {
  var encoder, jpegURI;
  encoder = new JPEGEncoder();
  jpegURI = encoder.encode(e.data, 100);
  return self.postMessage(jpegURI);
}, false);

//# sourceMappingURL=convertToImage.js.map
