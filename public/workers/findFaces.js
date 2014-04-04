importScripts('/workers/jpegencoder.js');

importScripts('/workers/blobConverter.js');

importScripts('/workers/uploader.js');

self.addEventListener('message', function(e) {
  var blob, encoder, image, index, jpegURI, _i, _len, _ref, _results, _self;
  _ref = e.data;
  _results = [];
  for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
    image = _ref[index];
    encoder = new JPEGEncoder();
    jpegURI = encoder.encode(image, 100);
    blob = blobConverter.convertDataURL(jpegURI);
    _self = self;
    _results.push(uploader.post(blob, (function(_this) {
      return function(face) {
        var faces;
        faces = JSON.parse(face);
        return _self.postMessage(faces);
      };
    })(this)));
  }
  return _results;
}, false);

//# sourceMappingURL=findFaces.js.map
