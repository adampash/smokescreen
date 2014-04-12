blobConverter =
  convertDataURL: (dataURL, type) ->
    type = type || "image/jpeg"
    blobBin = atob(dataURL.split(',')[1])
    array = []
    i = 0

    while i < blobBin.length
      array.push blobBin.charCodeAt(i)
      i++

    # try
    new Uint8Array(array)
      # file = new Blob(
      #   [new Uint8Array(array)],
      #   type: type
      # )
    # catch e
    #   # TypeError old chrome and FF
    #   window.BlobBuilder = window.BlobBuilder || 
    #                      window.WebKitBlobBuilder || 
    #                      window.MozBlobBuilder || 
    #                      window.MSBlobBuilder;
    #   if e.name == 'TypeError' && window.BlobBuilder
    #     bb = new BlobBuilder()
    #     bb.append([array.buffer])
    #     file = bb.getBlob("image/png")
    #   else if e.name == "InvalidStateError"
    #     # InvalidStateError (tested on FF13 WinXP)
    #     file = new Blob( [array.buffer], {type : "image/png"})
    #   file


