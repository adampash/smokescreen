importScripts('/workers/formdata.js')
importScripts('/assets/js/jquery.hive.pollen.js')

uploader =
  post: (file, callback) ->
    options = options || {}
    formdata = new FormData()
    formdata.append("upload", file)

    req = new XMLHttpRequest()
    req.onload = ->
      callback(@responseText)

    req.open("post", "http://localhost:3000/", true)
    req.send(formdata)
