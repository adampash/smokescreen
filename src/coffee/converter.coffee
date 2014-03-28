class window.Converter
  constructor: (@canvas, @frames, @fps, @player, options) ->
    @options = options || {}
    @convertCanvas = document.createElement('canvas')
    @convertCanvas.width = @canvas.width
    @convertCanvas.height = @canvas.height
    @convertContext = @convertCanvas.getContext('2d')
    @files = []
    @uploadedFiles = []
    @formdata = new FormData()
    @fps = @fps || 10
    @save = false
    @uploadedSprite
    @gifFinished = options.gifFinished

  reset: ->
    @files = []
    @uploadedFiles = []
    @formdata = new FormData()
    @fps = @fps || 10
    @uploadedSprite = null
    @save = false

  convertAndUpload: ->
    if !@convertingFrames?
      @convertingFrames = @frames

    if @convertingFrames.length > 0
      # log @convertingFrames.length if @convertingFrames.length%20==0
      file = @convertFrame(@convertingFrames.shift())
      @postImage(file,
       success: (response) =>
        window.faces.push response
        @convertAndUpload()
      )
    else
      log 'All done converting and uploading frames'
      alert 'DONE'

  runWorker: ->
    worker = new Worker('/workers/findFaces.js')

    worker.addEventListener('message', (e) =>
      log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'
      alert 'DONE'
      log 'start processing images now'
      @foundFaces = e.data
    , false)

    framesToProcess = (frame for frame in @frames by 5)
    @startedAt = new Date().getTime()
    worker.postMessage framesToProcess
    # for frame in @frames
    #   worker.postMessage frame
    # frame = @frames[10]
    # worker.postMessage frame

  convert: ->
    @files = []

    @files.push(@convertFrame(frame)) for frame in @frames
    @options.converted() if @options.converted?

  convertFrame: (frame) ->
    @convertContext.putImageData(frame, 0, 0)

    dataURL = @convertCanvas.toDataURL()

    @convertDataURL(dataURL)


  convertDataURL: (dataURL, type) ->
    type = type || "image/png"
    blobBin = atob(dataURL.split(',')[1])
    array = []
    i = 0

    while i < blobBin.length
      array.push blobBin.charCodeAt(i)
      i++

    try
      file = new Blob(
        [new Uint8Array(array)],
        type: type
      )
    catch e
      # TypeError old chrome and FF
      window.BlobBuilder = window.BlobBuilder || 
                         window.WebKitBlobBuilder || 
                         window.MozBlobBuilder || 
                         window.MSBlobBuilder;
      if e.name == 'TypeError' && window.BlobBuilder
        bb = new BlobBuilder()
        bb.append([array.buffer])
        file = bb.getBlob("image/png")
      else if e.name == "InvalidStateError"
        # InvalidStateError (tested on FF13 WinXP)
        file = new Blob( [array.buffer], {type : "image/png"})
      file


  totalFileSize: ->
    @files.reduce (acc, file) ->
      acc += file.size
    , 0

  framesInFinalGif: (loopStyle) ->
    if loopStyle == 'ping-pong'
      (@frames.length * 2) - 2
    else
      @frames.length

  # upload order:
  # 1) uploadToS3
  # 2) postPNGs
  # 3) atiwl.uploadToS3

  postImage: (file, options) ->
    options = options || {}
    formdata = new FormData()
    formdata.append("upload", file)

    $.ajax
      url: "http://localhost:3000/"
      type: "POST"
      data: formdata
      processData: false
      # contentType: false
      contentType: false
      xhrFields:
        withCredentials: false
      xhr: ->
        req = $.ajaxSettings.xhr()
        if (req)
          if options.progress
            req.upload.addEventListener('progress', (event) ->
              if event.lengthComputable
                options.progress(event)
            , false)
        req
    .done (response) =>
      if options.success
        options.success(response)
    .always ->
      if options.complete
        options.complete()
    .fail ->
      if options.error
        options.error()

  postPNGs: (options) ->
    for file, index in @files
      @formdata.append("upload[" + index + "]", file)
    # @formdata.append("sprite", @uploadedSprite)

    $.ajax
      url: "http://localhost:3000/"
      type: "POST"
      data: @formdata
      processData: false
      contentType: 'text/plain'
      xhrFields:
        withCredentials: false
      xhr: ->
        req = $.ajaxSettings.xhr()
        if (req)
          if options and options.progress
            req.upload.addEventListener('progress', (event) ->
              if event.lengthComputable
                options.progress(event)
            , false)
        req
    .done (response) =>
      if options and options.success
        options.success(response)
    .always ->
      console.log new Date().getTime() / 1000
      if options and options.complete
        options.complete()
    .fail ->
      if options and options.error
        options.error()

  upload: (loopStyle, options) ->
    loopStyle = loopStyle || false

    @appendToForm(i, file) for file, i in @files
    @formdata.append("ping", loopStyle == 'ping-pong')
    @formdata.append("fps", @fps)

    @formdata.append("authenticity_token", AUTH_TOKEN)

    if options and options.description
      @formdata.append("description", options.description)

    $.ajax
      url: "/gifs"
      type: "POST"
      data: @formdata
      processData: false
      contentType: false
      xhr: ->
        req = $.ajaxSettings.xhr()
        if (req)
          if options and options.progress
            req.upload.addEventListener('progress', (event) ->
              if event.lengthComputable
                options.progress(event)
            , false)
        req
    .done (response) ->
      if options and options.success
        options.success(response)
    .always ->
      if options and options.complete
        options.complete()
    .fail ->
      if options and options.error
        options.error()

  uploadToS3: (fileBlobs, options) ->
    fileBlobs = fileBlobs || @files
    $uploadForm = $('#png-uploader')

    for file, index in fileBlobs
      key = $uploadForm.data("key")
        .replace('{index}', index)
        .replace('{timestamp}', new Date().getTime())
        .replace('{unique_id}', Math.random().toString(36).substr(2,16))
        .replace('{extension}', 'png')

      fd = new FormData()
      fd.append('utf8', '✓')
      fd.append('key', key)
      fd.append('acl', $uploadForm.find('#acl').val())
      fd.append('AWSAccessKeyId', $uploadForm.find('#AWSAccessKeyId').val())
      fd.append('policy', $uploadForm.find('#policy').val())
      fd.append('signature', $uploadForm.find('#signature').val())
      fd.append('success_action_status', "201")
      fd.append('X-Requested-With', "xhr")
      fd.append('Content-Type', "image/png")
      fd.append("file", file)
      # fd.append("filename", "atiwl.gif")

      postURL = $uploadForm.attr('action')

      $.ajax
        url:  postURL
        type: "POST"
        data: fd
        processData: false
        contentType: false
        # xhr: ->
        #   req = $.ajaxSettings.xhr()
        #   if (req)
        #     req.upload.addEventListener('progress', (event) ->
        #       if event.lengthComputable
        #         progVal = Math.round(((event.loaded / event.total) * 6)/2)

        #         $('.progressBar .ball.loading').removeClass('loading')
        #         $($('.progressBar .ball')[progVal + 3]).addClass('loading')
        #         $('.progressBar .ball').slice(3, progVal + 3).addClass('loaded')
        #     , false)
        #   req
      .done (response) =>
        pngURL = $(response).find('Location').text()

        @uploadedFiles.push pngURL

        # if options and options.progress
        #   options.progress(@uploadedFiles.length / fileBlobs.length)
        # if @uploadedFiles.length == fileBlobs.length
        #   console.log 'all done'
        #   @sortUploads()
        if options and options.success
          options.success(response)
      .always ->
        if options and options.complete
          options.complete()
      .fail ->
        if options and options.error
          options.error()

  appendToForm: (index, file) ->
    @formdata.append("upload[" + index + "]", file)
