var blobConverter;

blobConverter = {
  convertDataURL: function(dataURL, type) {
    var array, bb, blobBin, e, file, i;
    type = type || "image/jpeg";
    blobBin = atob(dataURL.split(',')[1]);
    array = [];
    i = 0;
    while (i < blobBin.length) {
      array.push(blobBin.charCodeAt(i));
      i++;
    }
    try {
      return file = new Blob([new Uint8Array(array)], {
        type: type
      });
    } catch (_error) {
      e = _error;
      window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder || window.MSBlobBuilder;
      if (e.name === 'TypeError' && window.BlobBuilder) {
        bb = new BlobBuilder();
        bb.append([array.buffer]);
        file = bb.getBlob("image/png");
      } else if (e.name === "InvalidStateError") {
        file = new Blob([array.buffer], {
          type: "image/png"
        });
      }
      return file;
    }
  }
};

//# sourceMappingURL=blobConverter.js.map
