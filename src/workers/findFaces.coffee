importScripts('/workers/jpegencoder.js')
importScripts('/workers/blobConverter.js')
importScripts('/workers/uploader.js')


self.addEventListener('message', (e) ->

  for image, index in e.data
    encoder = new JPEGEncoder()
    jpegURI = encoder.encode(image, 100)

    blob = blobConverter.convertDataURL jpegURI

    _self = self
    uploader.post blob, (face) =>
      faces = JSON.parse face
      _self.postMessage(faces)

, false)

