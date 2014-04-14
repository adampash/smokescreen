$ ->
  window.dev = true
  window.log = (args) ->
    if false
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

    play: (trackIndex) ->
      log 'play'
      if trackIndex?
        @currentTrack = trackIndex
        @queue @tracks[trackIndex]
      else if @currentTrack < @tracks.length
        @queue @tracks[@currentTrack]

    nextTrack: ->
      @currentTrack++
      @play()

    prevTrack: ->
      @currentTrack--
      @play()

    queue: (track) ->
      log 'queue', track

      track.play(
        @, =>
          @nextTrack()
      )

    addTrack: (track) ->
      @tracks.push track
      if @currentTrack == @tracks.length - 1
        @play(@tracks.length - 1)

$ ->
  class window.Sequence
    constructor: (options) ->
      @options = options
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
          @video = new CanvasPlayer @canvas,
            @options.frames || window.recorder.capturedFrames,
            @options.fps || window.recorder.fps,
            addSpacer: @options.addSpacer || false
            progress: (index) =>
              @drawAnimation(index) if @drawAnimation?
          @video.play(
            player: @player
            ended: =>
              @ended()
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

    # drawAnimation: ->
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
        @littleCanvas.width = 960 # @canvas.width /  3
        @littleCanvas.height = 540 # @canvas.width / 3
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
      if @littleCanvas?
        window.spacer = spacer

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

class window.soundAnalyzer
  constructor: ->
    @low = 1000
    @high = 4000
  playSound: (soundURL) ->
    # http://stackoverflow.com/questions/10105063/how-to-play-a-notification-sound-on-websites 
    @shouldAnalyze = true
    soundURL = soundURL or "/assets/audio/awobmolg.m4a"
    console.log('playing sound: ' + soundURL)
    $('body').append '<audio id="poem" autoplay="autoplay"><source src="' + soundURL + '" type="audio/mpeg" /><embed hidden="true" autostart="true" loop="false" src="' + soundURL + '" /></audio>'

    audioContext = new (window.AudioContext||window.webkitAudioContext)()

    @audioElement = document.getElementById("poem")

    @analyzer = audioContext.createAnalyser()
    @analyzer.fftSize = 64
    @frequencyData = new Uint8Array(@analyzer.frequencyBinCount)

    @audioElement.addEventListener("canplay", =>
      source = audioContext.createMediaElementSource(@audioElement)
      console.log 'can play'
      source.connect(@analyzer)
      @analyzer.connect(audioContext.destination)
    )

    @audioElement.addEventListener('ended', =>
      @shouldAnalyze = false
      console.log('ended')
    , false)
    # audioElement.addEventListener('canplaythrough', voiceLoaded, false)
    @audioElement.addEventListener('playing', @analyze, false)

    $intensity = $("#intensity")

  analyze: =>
    @analyzer.getByteFrequencyData(@frequencyData)
    magnitude = 0
    for frequency in @frequencyData
      magnitude += frequency
    # i = 0
    # while i < @frequencyData.length
    #   magnitude += @frequencyData[i]
    #   i++

    @high = Math.max @high, magnitude
    @low = Math.min @low, magnitude

    window.audioIntensity = (magnitude/@high)
    console.log audioIntensity
    # opacity = 0.8 - (magnitude/frequencyData.length)/40
    # $intensity.css("opacity": opacity)

    setTimeout(@analyze, 33) if @shouldAnalyze

class window.Faces
  constructor: (faces, @scale) ->
    if faces.length?
      @allFaces = @flatten faces
    else
      @allFaces = faces || []
    @calculateAvgFace()

    @facesByFrames = faces

  groupFaces: (frames, faces) ->
    if !frames?
      @removeAnomolies()
    frames = frames || @reconstruct()
    faces = faces || []
    frameNumber = frameNumber || 0

    thisFace = new Face()
    faces.push thisFace

    # add the first face available in the array of frames
    firstFace = false
    i = 0
    until firstFace || i > frames.length
      if frames[i]? and frames[i].length
        firstFace = frames[i][0]
        frames[i].splice(0, 1)
      else
        thisFace.frames.push undefined
        i++

    thisFace.frames.push firstFace

    if !@empty(frames)
      thisFace.findRelatives(frames)

    # check if frames still has faces in it
    # if it does, tail recurse this method
    if @empty(frames)
      faces = @verifyFrameNumbers(faces, frames.length)
      faces = @removeProbableFalse(faces)
      faces = @applyScale(faces)
      @faceMap = faces
      faces
    else
      @groupFaces(frames, faces)

  applyScale: (faces) ->
    for face in faces
      face.applyScale(@scale)
    faces

  removeProbableFalse: (faces) ->
    newFaces = []
    for face in faces
      console.log face.probability()
      if face.probability() > 0.18
        newFaces.push face
      else
        console.log 'removing ', face
    newFaces

  verifyFrameNumbers: (faces, numFrames) ->
    console.log 'all faces should have ' + numFrames + ' frames'
    fixedFaces = faces.map (face) ->
      if face.frames.length < numFrames
        until face.frames.length == numFrames
          face.frames.push undefined
      else if face.frames.length > numFrames
        face.frames.splice(numFrames, -1)
      face
    fixedFaces

  empty: (arrayOfArrays) ->
    i = 0
    empty = true
    console.log 'checking for empty'
    while empty and i < arrayOfArrays.length
      empty = false if arrayOfArrays[i].length > 0
      i++
    empty

  prepareForCanvas: (faces) ->
    frames = []
    for face in faces
      for frame, index in face.frames
        frames[index] = [] unless frames[index]?
        frames[index].push frame if frame?
    frames


  removeAnomolies: ->
    goodFaces = []
    newNumFaces = 0
    for face, index in @allFaces
      if !face.frame
        # face size is within x% of avg face size
        if Math.abs(1 - face.width*face.height / @avgFace) < 0.7
          goodFaces.push face
          newNumFaces++
      else
        goodFaces.push face

    console.log 'started with ' + @allFaces.length + ' and ending with ' + goodFaces.length
    @allFaces = goodFaces
    @numFaces = newNumFaces


  flatten: (faces) ->
    newFaces = []
    @numFaces = 0
    faces.map (facesArray, index) =>
      newFaces.push
        frame: true
        num: index
      facesArray.map (face) =>
        @numFaces++
        newFaces.push face
    newFaces

  reconstruct: ->
    console.log 'there are ' + @facesByFrames.length + ' frames and ' + @numFaces + ' faces total which adds up to ' + @allFaces.length
    facesInFrames = []
    for face, index in @allFaces
      if face.frame
        i = 1
        facesInFrames.push []
        while typeof @allFaces[index + i] is "object" and @allFaces[index + i].x?
          facesInFrames[facesInFrames.length-1].push @allFaces[index + i]
          i++
    facesInFrames

  calculateAvgFace: ->
    totalFaceArea = @allFaces.reduce((accumulator, face) ->
      if face.width?
        accumulator += face.width * face.height
      else
        accumulator
    , 0)
    @avgFace = totalFaceArea / @numFaces


class window.Face
  constructor: () ->
    @frames = []
    @started = null


  applyScale: (scale) ->
    for frame in @frames
      for key of frame
        frame[key] = Math.round(frame[key] * scale)
    @

  probability: ->
    1 - @emptyFrames() / @frames.length

  emptyFrames: ->
    numEmpty = 0
    for frame in @frames
      numEmpty++ if frame is undefined or frame is false

    numEmpty

  padFrames: (padding) ->
    newFrames = []
    for frame in @frames
      newFrames.push frame
      for num in [padding..0]
        newFrames.push undefined

    @frames = newFrames


  fillInBlanks: (padding) ->
    if padding?
      @padFrames(padding)
    i = 0
    for frame, index in @frames
      if frame is undefined
        @fillIn(index)

        i++
    console.log 'we had ' + i + ' frames that needed filling in'
    @fillInEyesAndMouth()

  fillIn: (index) ->
    if index is 0
      # find first match and fill in with it
      match = false
      i = 1
      until match
        match = @frames[index+i] unless @frames[index+i] is undefined
        i++
      @frames[index] = match

    else if index is @frames.length - 1
      @frames[index] = @frames[index-1]
      #only go backward
    else
      # go in both directions
      lastFrame = @frames[index-1]
      match = false
      i = 1
      until match or index+i >= @frames.length
        unless @frames[index+i] is undefined
          match = @frames[index+i] 
        else
          i++
      if match
        @fillBetween(index-1, index+i)
        # @frames[index] = match
      else
        @frames[index] = lastFrame

  fillBetween: (index1, index2) ->
    numFrames = index2 - index1
    firstFrame = @frames[index1]
    lastFrame = @frames[index2]

    xDiff = firstFrame.x - lastFrame.x
    yDiff = firstFrame.y - lastFrame.y
    widthDiff = firstFrame.width - lastFrame.width

    applyDiff =
      x: Math.round xDiff / numFrames
      y: Math.round yDiff / numFrames
      width: Math.round widthDiff / numFrames

    i = index1+1
    until i == index2
      @frames[i] =
        x: @frames[i-1].x - applyDiff.x
        y: @frames[i-1].y - applyDiff.y
        width: @frames[i-1].width - applyDiff.width
        height: @frames[i-1].height - applyDiff.width
      i++


  findRelatives: (frames) ->
    # add the first face available in the array of frames
    nextFrame = false
    until nextFrame || @frames.length > frames.length
      if frames[@frames.length]? and frames[@frames.length].length
        nextFrame = frames[@frames.length]
      else
        @frames.push undefined

    closestFaces = @findClosestFaceIn(nextFrame) if nextFrame

    bestMatch = @returnBestMatch(closestFaces)
    console.log "bestMatch is", bestMatch
    if bestMatch
      @frames.push bestMatch
    else
      @frames.push undefined

    if @frames.length < frames.length
      @findRelatives(frames)
    else
      @

  returnBestMatch: (faces) ->
    match = false

    if faces? and faces.length > 0
      face = @getLatestFace()

      i = 0
      until match or i > faces.length
        if faces[i]?
          testFace = faces[i]
          if Math.abs(1 - face.width / testFace.width) < 0.6 and 
                              @distance(face, testFace) < face.width * 0.6
            faces.splice(i, 1)
            match = testFace
        i++
    return match

  getLatestFace: ->
    i = 1
    face = false
    until face || i > @frames.length
      face = @frames[@frames.length-i]
      i++

    face

  fillInEyesAndMouth: ->
    for frame in @frames
      frame.eyebar =
        x: Math.round(frame.x + frame.width/10)
        width: Math.round(frame.width/10 * 8)
        y: Math.round(frame.y + frame.height / 3.7)
        height: Math.round(frame.height / 4)
      frame.mouth =
        x: Math.round(frame.x + frame.width/4)
        width: Math.round(frame.width/2)
        y: Math.round(frame.y + (frame.height/5*2.8))
        height: Math.round(frame.height/2)
    @frames

  findClosestFaceIn: (frame) ->
    face = @getLatestFace()
    sorted = frame.sort (a, b) =>
      @distance(a, face) - @distance(b, face)

    sorted

  distance: (obj1, obj2) ->
    Math.sqrt(Math.pow((obj1.x - obj2.x), 2) + Math.pow((obj1.y - obj2.y), 2))


  isBegun: ->
    return @started if @started?
    if @frames.length > 0
      for frame in @frames
        if frame? and frame
          @started = true
          return @started

      console.log 'false'
      return false

    else
      return false

$ ->
  duration = 2
  window.camSequence = new Sequence
      type: 'sequence'
      src: 'webcam'
      aspect: 16/9
      duration: duration
      onStart: ->
        @recordCam(duration)

  camSequence.drawAnimation = (context, elapsed) ->
    $('body').append '<div class="cover"></div>'

  camSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()
    setTimeout ->
      $('.cover').remove()
    , 500

  camSequence.recordCam = (seconds) ->
    window.recorder = @record(@video.canvas, seconds, false)
    window.littleRecorder = @record(@video.littleCanvas, seconds, true)

  camSequence.record = (canvas, seconds, convert) ->
    recorder = new Recorder canvas

    if convert
      complete = =>
        window.converter = new Converter recorder.canvas,
                            recorder.capturedFrames,
                            recorder.fps,
                            null,
                            converted: ->
        converter.runWorker()
    else
      complete = =>
        window.allFrames = recorder.capturedFrames.slice(0)
        @doProcessing(recorder.capturedFrames, recorder.fps)


    fps = 30
    recorder.record seconds, fps,
      complete: complete

    recorder

  camSequence.doProcessing = (frames, fps) ->
    frames = frames.slice(0)
    window.processor = new Processor frames, null, fps
    processor.blackandwhite()

class window.CanvasPlayer
  constructor: (@canvas, @frames, @fps, @options) ->
    @options = @options || {}
    @addSpacer = @options.addSpacer
    @progress = @options.progress
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
        unless @loop
          return @options.ended() if @options.ended
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

    if @addSpacer
      spacer = Math.round((@canvas.height - frame.width * 9/16) / 2)
      @context.putImageData(frame, 0, spacer)
    else
      @context.putImageData(frame, 0, 0)
    @progress(index) if @progress

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

    framesToProcess = (frame for frame in @frames by 5)

    @foundFaces = []
    worker.addEventListener('message', (e) =>
      log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'
      log 'start processing images now'
      @foundFaces.push e.data
      if @foundFaces.length == framesToProcess.length
        window.matchedFaces = new Faces(@foundFaces, (player.displayWidth/960))
        bestBets = matchedFaces.groupFaces()
        if bestBets[0]? and bestBets[0].isBegun()
          for face in bestBets
            face.fillInBlanks(3)
            processor.zoomOnFace(face)
          # processor.drawFaceRects(matchedFaces.prepareForCanvas(bestBets), player.displayWidth / 960)
          processor.queueEyebarSequence(matchedFaces.faceMap)
        else
          console.log 'no go'
        @options.converted() if @options.converted?
    , false)

    @startedAt = new Date().getTime()
    for frame in framesToProcess
      worker.postMessage [frame]
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

class window.Cropper
  constructor: (@goalDimensions) ->
    @spacer = (@goalDimensions.height - @goalDimensions.width * 9/16) / 2

    @transitionCanvas = @createCanvas @goalDimensions
    @transitionContext = @createContext @transitionCanvas

    @goalCanvas = @createCanvas @goalDimensions
    @goalContext = @createContext @goalCanvas


  queue: (face, frames) ->
    @frameQueue = frames.slice(0)
    @currentFace = face
    @finishedFrames = []

  start: (callback) ->
    @doneCallback = callback || @doneCallback
    @finishedFrames.push @zoomToFit @currentFace, @frameQueue.shift(), true
    if @frameQueue.length > 0
      setTimeout =>
        @start()
      , 50
    else
      @doneCallback @finishedFrames



  zoomToFit: (face, frame, transparent) ->
    cropCoords = @convertFaceCoords face
    # above needs to account for aspect adjustment on zoom
    debugger unless frame?
    @transitionContext.putImageData frame, 0, 0
    cropData = @transitionContext.getImageData cropCoords.x,
                                   cropCoords.y,
                                   cropCoords.width,
                                   cropCoords.height

    scaleFactor = @goalDimensions.width/cropCoords.width
    canvas = @createCanvas
                width: cropData.width
                height: cropData.height
    @createContext(canvas).putImageData cropData, 0, 0

    @goalContext.scale scaleFactor, scaleFactor
    @goalContext.drawImage canvas, 0, 0

    @goalContext.scale 1/scaleFactor, 1/scaleFactor
    frame = @goalContext.getImageData 0, 0, @goalCanvas.width, @goalCanvas.height

    frame = @makeTransparent frame if transparent

    frame

  makeTransparent: (frame) ->
    targetWidth = 175
    frameWidth = frame.width
    idata = frame.data
    center = 
      x: frame.width / 2
      y: frame.height / 2.7
    diagonal = Math.sqrt(Math.pow(center.x, 2) + Math.pow(center.y, 2))
    for pixel, index in idata by 4
      pixelNum = index/4
      y = Math.floor pixelNum / frameWidth
      thisPixel =
        y: y
        x: pixelNum - y*frameWidth
      distance = @distance(thisPixel, center)

      if distance > targetWidth
        idata[index+3] = 0
      else
        distance = distance * 1.3
        idata[index+3] = 255 - (distance/targetWidth * 255)

    frame.data = idata
    frame

  distance: (obj1, obj2) ->
    Math.sqrt(Math.pow((obj1.x - obj2.x), 2) + Math.pow((obj1.y - obj2.y), 2))




  convertFaceCoords: (face) ->
    width = face.width * 4
    height = width * 9/16
    center_x = face.x + face.width / 2
    center_y = face.y + face.height / 2
    # console.log 'center_x', center_x
    newCoords =
      x: Math.round center_x - width/2
      y: Math.round (center_y - height/1.9 + @spacer)
      width: Math.round width
      height: Math.round height




  createCanvas: (dimensions) ->
    canvas = document.createElement 'canvas'
    canvas.width = dimensions.width
    canvas.height = dimensions.height
    canvas

  createContext: (canvas) ->
    context = canvas.getContext '2d'


window.debug =
  frame: (frame) ->
    canvas = @createCanvas
              width: frame.width
              height: frame.height
    $('body').html canvas
    context = @createContext canvas
    context.putImageData frame, 0, 0

  createCanvas: (dimensions) ->
    canvas = document.createElement 'canvas'
    canvas.width = dimensions.width
    canvas.height = dimensions.height
    canvas

  createContext: (canvas) ->
    context = canvas.getContext '2d'


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
  setTimeout ->
    $(window).trigger 'click'
  , 1000

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

  # playbackCamSequence.drawAnimation = (context, elapsed) ->
  #   @context.clearRect(0, 0,
  #                     @canvas.width,
  #                     @canvas.height)





  playbackCamSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()

class window.Processor
  constructor: (@frames, @faces, @options) ->
    @newFrames = []
    @playFrames = []

  zoomOnFace: (face) ->
    return if !face.frames? or face.frames.length < 7
    centerFace = face.frames[6]
    # TODO face.averageFace
    crop = new Cropper
      width: player.displayWidth
      height: player.displayHeight

    crop.queue(centerFace, allFrames)
    crop.start (frames) =>
      console.log 'done running cropper'
      @addSequence frames, true

  blackandwhite: (options) ->
    options = options || {}
    newFrames = []
    worker = new Worker('/workers/bnw.js')

    worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @playFrames = newFrames
        @addSequence()
      else
        worker.postMessage [@frames[newFrames.length]]
    , false)

    @startedAt = new Date().getTime()
    # for frame, index in @frames
    worker.postMessage [@frames[0]]


  drawFaceRects: (@faces, @scale) ->
    newFrames = []
    @worker = new Worker('/workers/drawFaceRect.js')

    @worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @addSequence(newFrames)
      else
        @sendFrame newFrames.length, scale
    , false)

    @startedAt = new Date().getTime()
    # @newFaces = []
    @newFaces = @faces

    @sendFrame 0, scale

  sendFrame: (index, scale) ->
    #TODO Debug when frame is undefined here...
    frame = @frames[index]
    unless frame?
      debugger
      # frame = @frames[index - 1]
    if frame?
      params =
        frames: [frame]
        frameNumber: index
        faces: @newFaces[index]
        scale: scale || 3
        spacer: Math.round(window.spacer)
      @worker.postMessage params
    else
      console.log 'shit wtf no frame?'
      @sendFrame index + 1 unless index <= @frames.length

  queueEyebarSequence: (faces) ->
    # figure out why frames is empty here
    sequence = new Sequence
        type: 'sequence'
        aspect: 16/9
        duration: 3
        src: 'CanvasPlayer'
        frames: window.allFrames
        faces: faces
        name: 'Eyebar'
        # addSpacer: false
    sequence.ended = ->
      @callback() if @callback?
      @cleanup()
      @video.cleanup()
    sequence.drawAnimation = (index) ->
      for thisFace in @options.faces
        face = thisFace.frames[index]

        @context.fillStyle = 'rgba(0, 0, 0, 1.0)'
        @context.fillOpacity = 0.1
        @context.fillRect(face.eyebar.x, face.eyebar.y, face.eyebar.width, face.eyebar.height)
        # @context.fillRect(face.mouth.x, face.mouth.y, face.mouth.width, face.mouth.height)

        # @context.font = "bold 40px sans-serif"
        # @context.fillText("x", face.mouth.x, face.mouth.y)
        # @context.fillRect(face.mouth.x, face.mouth.y, face.mouth.width, face.mouth.height)

        mouthQuarterX = face.mouth.width/4
        mouthQuarterY = face.mouth.height/4

        @context.beginPath()
        @context.moveTo(face.mouth.x, face.mouth.y + mouthQuarterY)
        @context.lineTo(face.mouth.x + mouthQuarterX*3, face.mouth.y+face.mouth.height)
        @context.lineTo(face.mouth.x + face.mouth.width, face.mouth.y+mouthQuarterY*3)
        @context.lineTo(face.mouth.x + mouthQuarterX, face.mouth.y)
        @context.fill()
        @context.moveTo(face.mouth.x + mouthQuarterX*3, face.mouth.y)
        @context.lineTo(face.mouth.x, face.mouth.y+mouthQuarterY*3)
        @context.lineTo(face.mouth.x+mouthQuarterX, face.mouth.y+face.mouth.height)
        @context.lineTo(face.mouth.x+face.mouth.width, face.mouth.y+mouthQuarterY)
        @context.fill()
    player.addTrack sequence


  saturate: (percent) ->
    newFrames = []
    worker = new Worker('/workers/saturate.js')

    worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @playFrames = newFrames
        @addSequence()
    , false)

    @startedAt = new Date().getTime()
    for frame in @frames
      worker.postMessage [frame]

  blur: (rate) ->
    newFrames = []
    worker = new Worker('/workers/blur.js')

    worker.addEventListener('message', (e) =>
      newFrames.push e.data[0]
      if newFrames.length == @frames.length
        log 'time to add sequence to player'
        log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'

        @playFrames = newFrames
        @addSequence()
    , false)

    @startedAt = new Date().getTime()
    for frame in @frames
      worker.postMessage [frame]

  addSequence: (frames, addSpacer) ->
    frames = frames || @playFrames
    addSpacer = addSpacer || false
    sequence = new Sequence
        type: 'sequence'
        aspect: 16/9
        duration: 3
        src: 'CanvasPlayer'
        frames: frames
        addSpacer: addSpacer
    sequence.ended = ->
      @callback() if @callback?
      @cleanup()
      @video.cleanup()
    player.addTrack sequence
    log 'added track'
    # player.addTrack new VideoTrack
    #   src: '/assets/videos/ocean.mp4'
    #   aspect: 16/9

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
      playbackCamSequence
    ,
      new VideoTrack
        src: '/assets/videos/short.mov'
        aspect: 16/9
    ,
      playbackCamSequence
  ]

  $(window).resize ->
    player.setDimensions()
    # player.tracks[player.currentTrack].setDimensions()

  $(window).on 'click', ->
    $('h1').remove()
    player.play()
