# importScripts('/workers/usain-png.js')
importScripts('/workers/jpegencoder.js')

self.addEventListener('message', (e) ->

  encoder = new JPEGEncoder()
  jpegURI = encoder.encode(e.data, 100)

  # self.postMessage(e.data)
  self.postMessage(jpegURI)

, false)

