var blobConverter;

blobConverter = {
  convertDataURL: function(dataURL, type) {
    var array, blobBin, i;
    type = type || "image/jpeg";
    blobBin = atob(dataURL.split(',')[1]);
    array = [];
    i = 0;
    while (i < blobBin.length) {
      array.push(blobBin.charCodeAt(i));
      i++;
    }
    return new Uint8Array(array);
  }
};

//# sourceMappingURL=blobConverter.js.map
