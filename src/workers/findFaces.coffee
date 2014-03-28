importScripts('/workers/jpegencoder.js')
importScripts('/workers/blobConverter.js')
importScripts('/workers/uploader.js')


self.addEventListener('message', (e) ->
  @faces = []

  for image, index in e.data
    encoder = new JPEGEncoder()
    jpegURI = encoder.encode(image, 100)

    blob = blobConverter.convertDataURL jpegURI

    _self = self
    uploader.post blob, (face) =>
      @faces.push face
      if @faces.length == e.data.length
        _self.postMessage(@faces)

, false)

