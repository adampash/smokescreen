$ ->
  window.dev = true
  window.log = (args) ->
    if dev
      console.log.apply console,  arguments

  if dev
    $('body').append $('<script src="//localhost:35729/livereload.js"></script>')

$ ->
  class window.Player
    constructor: (@tracks) ->
      @currentTrack = 0
      @videoPlaying = false

      @setDimensions()

    setDimensions: (canvas) ->
      @displayWidth = $(document).width()
      @displayHeight = $(document).height()

      @tracks[@currentTrack].setDimensions()

    play: ->
      log 'play'
      if @currentTrack < @tracks.length
        @queue @tracks[@currentTrack]

    nextTrack: ->
      @currentTrack++
      @play()

    queue: (track) ->
      log 'queue', track

      track.play(
        @, =>
          @nextTrack()
      )

$ ->
  class window.Sequence
    constructor: (options) ->
      @type = 'sequence'
      @src = options.src
      @aspect = options.aspect
      @duration = options.duration

      @onStart = options.onStart if options.onStart?

      @canvas = @createCanvas()
      @canvas.id = new Date().getTime()
      @context = @createContext @canvas

      @canvases = []
      @canvases.push @canvas

      @playing = false

      _this = @
      $(window).resize =>
        if @playing
          @setDimensions()


    setDimensions: =>
      if @player?
        @canvases.map (canvas) ->
          canvas.width = @player.displayWidth
          canvas.height = @player.displayHeight
        if @video
          @video.setDimensions()


    play: (player, callback) ->
      $('body').append(@canvas)
      log 'playSequence'
      @playing = true
      @player = player
      @callback = callback

      @setDimensions()

      if @src?
        if @src is 'webcam'
          log 'it is a webcam'
          @src = webcam.src
          @video = new VideoTrack
            src: @src
            aspect: @aspect
            littleCanvas: true
            shouldDraw: false
          @video.play(@player, null,
            onplaystart: =>
              @onStart() if @onStart?
          )
          @startSequence()
          @canvases.push @video
        else if @src is 'CanvasPlayer'
          @video = new CanvasPlayer @canvas, window.recorder.capturedFrames, window.recorder.fps
          @video.play(
            player: @player
          )
        else
          @video = new VideoTrack
            src: @src
            aspect: @aspect
          @video.play(@player, null
            onplaystart: =>
              @startSequence()
          )
      else
        @startSequence()

    startSequence: ->
      @sequenceStart = new Date()
      @drawSequence()

    drawSequence: =>
      elapsed = (new Date() - @sequenceStart) / 1000
      @drawAnimation(@, elapsed)

      if elapsed < @duration
        requestAnimationFrame =>
          @drawSequence()
      else
        log 'end sequence'
        @ended()

    drawAnimation: ->
      # to be overridden by new object

    cleanup: ->
      setTimeout =>
        $(@canvas).remove()
      , 300
      @context.clearRect(0, 0,
               @canvas.width,
               @canvas.height)

    createCanvas: ->
      canvas = document.createElement 'canvas'
      canvas

    createContext: (canvas) ->
      context = canvas.getContext '2d'

$ ->
  window.testSequence =
    new Sequence
      type: 'sequence'
      src: '/assets/videos/short.mov'
      aspect: 16/9
      duration: 5

  testSequence.drawAnimation = (context, elapsed) ->
    x = elapsed * 100
    y = elapsed * 100
    @context.clearRect(0, 0,
                      @canvas.width,
                      @canvas.height)


    @context.fillStyle = 'rgba(0, 100, 0, 0.4)'
    @context.fillOpacity = 0.1
    @context.fillRect(x, y, 400, 400)

  testSequence.ended = ->
    @callback() if @callback?
    @cleanup()

$ ->
  class window.VideoTrack
    constructor: (options) ->
      @type = 'video'
      @src = options.src
      @aspect = options.aspect

      @canvas = @createCanvas()
      @canvas.id = new Date().getTime()
      @context = @createContext @canvas

      @videoPlaying = false

      @shouldDraw = options.shouldDraw || true

      if options.littleCanvas?
        @littleCanvas = @createCanvas()
        @littleCanvas.width = 480
        @littleCanvas.height = 270
        @littleContext = @createContext @littleCanvas


    play: (player, callback, options) ->
      log 'playVideo'
      @player = player
      @callback = callback
      if options
        @onplaystart = options.onplaystart if options.onplaystart?

      $('body').prepend(@canvas)

      @setDimensions()

      @video = document.createElement 'video'
      @video.src = @src

      @setupVideoListeners @video

      @video.play()


    setDimensions: ->
      if @player?
        @canvas.width = @player.displayWidth
        @canvas.height = @player.displayHeight


    drawVideo: =>
      height = @player.displayWidth / @aspect
      spacer = (@player.displayHeight - height) / 2

      @context.drawImage(@video,0,spacer, @player.displayWidth, height)
      if @littleCanvas?
        @littleContext.drawImage(@video,0,0, @littleCanvas.width, @littleCanvas.height);


      if @videoPlaying
        requestAnimationFrame =>
          @drawVideo()

    setupVideoListeners: (video) =>
      video.addEventListener 'playing', (event) =>
        @onplaystart() if @onplaystart?
        @videoPlaying = true
        @drawVideo() if @shouldDraw

      video.addEventListener 'ended', (event) =>
        if @video is event.srcElement
          @videoPlaying = false

          # cleanup
          @cleanup()

          @callback() if @callback?


    cleanup: ->
      setTimeout =>
        $(@canvas).remove()
      , 300

    createCanvas: ->
      canvas = document.createElement 'canvas'
      canvas

    createContext: (canvas) ->
      context = canvas.getContext '2d'

$ ->
  duration = 3
  window.camSequence = new Sequence
      type: 'sequence'
      src: 'webcam'
      aspect: 16/9
      duration: duration
      onStart: ->
        @recordCam(duration)

  camSequence.drawAnimation = (context, elapsed) ->

  camSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()

  camSequence.recordCam = (seconds) ->
    window.recorder = @record(@video.canvas, seconds, false)
    window.littleRecorder = @record(@video.littleCanvas, seconds, true)

  camSequence.record = (canvas, seconds, convert) ->
    recorder = new Recorder canvas

    if convert
      complete = =>
        log 'recording complete'
        window.converter = new Converter recorder.canvas,
                            recorder.capturedFrames,
                            recorder.fps,
                            null,
                            converted: ->
                              log 'converted'
        # converter.convertAndUpload()
        converter.runWorker()
    else
      complete = null

    fps = 30
    recorder.record seconds, fps,
      complete: complete

    recorder


class window.CanvasPlayer
  constructor: (@canvas, @frames, @fps) ->
    @options = {}
    @paused = false
    @context = @canvas.getContext('2d')
    @index = 0
    @fps = @fps || 30
    @loopStyle = 'beginning'
    @loop = false
    @increment = true
    @startFrame = 1
    @endFrame = @frames.length - 1

  reset: ->
    @frames = []
    @options = {}
    @paused = false
    @index = 0
    @fps = @fps || 30
    @loopStyle = 'beginning'
    @increment = true
    @startFrame = 0

  setDimensions: ->
    if @player?
      @canvas.width = @player.displayWidth
      @canvas.height = @player.displayHeight

  play: (options) ->
    @player = options.player if options.player?
    @timeout = 1/@fps * 1000
    unless @paused
      @options = options || @options
      if @endFrame > @index
        if @index <= @startFrame
          @index = @startFrame
          @increment = true
        if @increment then @index++ else @index--
      else
        log "END THIS GUY", @endFrame, @index
        unless @loop
          debugger
          return options.ended() if options.ended
        if @loopStyle == 'beginning'
          @index = @startFrame
        else
          @index = @endFrame - 1
          @increment = false
      @paintFrame(@index)

    setTimeout =>
      @play(options)
    , @timeout

  pause: ->
    @paused = !@paused

  paintFrame: (index) ->
    return false if index >= @frames.length || index < 0
    @index = index || @index
    frame = @frames[@index]

    @context.putImageData(frame, 0, 0)
    @options.progress() if @options.progress

  cleanup: ->
    setTimeout =>
      $(@canvas).remove()
    , 300

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

  toDataURL: (frame) ->
    @convertContext.putImageData(frame, 0, 0)

    dataURL = @convertCanvas.toDataURL()

  convertFrame: (frame) ->
    dataURL = @toDataURL(frame)

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
      log new Date().getTime() / 1000
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

# GET USER MEDIA
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia

constraints =
  audio: false
  video:
    mandatory:
      minWidth: 1280
      minHeight: 720

successCallback = (stream) ->
  window.webcam = stream # stream available to console
  if (window.URL)
    webcam.src = window.URL.createObjectURL(stream)
  else
    webcam.src = stream

errorCallback = (error) ->
  log("navigator.getUserMedia error: ", error)

navigator.getUserMedia(constraints, successCallback, errorCallback)

$ ->
  window.playbackCamSequence = new Sequence
      type: 'sequence'
      aspect: 16/9
      duration: 3
      src: 'CanvasPlayer'
      # onStart: ->
      #   @recordCam(3)

  playbackCamSequence.drawAnimation = (context, elapsed) ->
    @context.clearRect(0, 0,
                      @canvas.width,
                      @canvas.height)





  playbackCamSequence.ended = ->
    @callback() if @callback?
    console.log 'callback and cleanup'
    @cleanup()
    @video.cleanup()

class window.Recorder
  constructor: (@canvas) ->
    @capturedFrames = []
    @context = @canvas.getContext('2d')
    @width = @canvas.width
    @height = @canvas.height

  reset: ->
    @capturedFrames = []


  record: (seconds, @fps, @options) ->
    @options = @options || {}
    @fps = @fps || 30
    seconds = seconds || 3
    @totalFrames = seconds * @fps
    frames = @totalFrames
    @captureFrames(frames)

  captureFrames: (frames) =>
    @options = @options || {}

    if frames > 0
      @capturedFrames.push(@context.getImageData(0, 0, @width, @height))

      frames--
      setTimeout =>
        @captureFrames(frames)
      , 1000/@fps
      if @options.progress
        @options.progress((@totalFrames - frames) / @totalFrames,
                          @capturedFrames[@capturedFrames.length-1]) 
    else
      @options.complete() if @options.complete



$ ->
  window.faces = []
  window.player = new Player [
      camSequence
    ,
      testSequence
    ,
    #   playbackCamSequence
    # ,
      new VideoTrack
        src: '/assets/videos/short.mov'
        aspect: 16/9
    ,
      new VideoTrack
        src: '/assets/videos/ocean.mp4'
        aspect: 16/9
    ,
  ]

  $(window).resize ->
    player.setDimensions()
    # player.tracks[player.currentTrack].setDimensions()

  $(window).on 'click', ->
    $('h1').remove()
    player.play()

