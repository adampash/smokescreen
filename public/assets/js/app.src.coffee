$ ->
  window.dev = true
  window.log = (args) ->
    if true
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
  constructor: (@player) ->
    @all = 0
    @counter = 0
    @low = 1000
    @high = 4000
  playSound: (soundURL) ->
    @shouldAnalyze = true
    soundURL = soundURL or "/assets/audio/AWOBMOLGQUIET.mp3"
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
      log 'average level: ' + @all/@counter
      log('audio ended')
      @audioElement.removeEventListener('playing', @analyze, false)
      $('#poem').remove()
    , false)
    # audioElement.addEventListener('canplaythrough', voiceLoaded, false)
    @audioElement.addEventListener('playing', @analyze, false)

    $intensity = $("#intensity")

  analyze: =>
    log 'analyze'
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
    # @all += magnitude
    # @counter++

    magnitude = (magnitude - 2000) / (@high-2000)
    window.audioIntensity = Math.max Math.min(magnitude, 1), 0

    # if @player? and @player.smoker.type?
    #   # log 'pulse it'
    #   @player.smoker.pulseMouths @player.ctx, @player.cPlayer.index, @player.smoker.type, audioIntensity

    setTimeout(@analyze, 10) if @shouldAnalyze

class Faces
  constructor: (faces, @scale) ->
    if faces.length?
      @allFaces = @flatten faces
    else
      @allFaces = faces || []
    @calculateAvgFace()

    @facesByFrames = faces

  sortByCertainty: (faces) ->
    faces.sort (a, b) ->
      b.certainty - a.certainty
    faces


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
      # faces = @applyScale(@scale)
      @faceMap = faces
      faces
    else
      @groupFaces(frames, faces)

  applyScale: (scale) ->
    for face in @faceMap
      face.applyScale(scale)
    @faceMap

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
    faces = faces or @faceMap
    frames = []
    for face in faces
      for frame, index in face.frames
        frames[index] = [] unless frames[index]?
        frames[index].push frame if frame?
    frames

  fillInBlanks: ->
    for face in @faceMap
      face.fillInBlanks(3)
    @faceMap

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


class Face
  constructor: () ->
    @frames = []
    @started = null


  getAverageFace: ->
    return @averageFace if @averageFace?
    allX = 0
    allY = 0
    allWidth = 0
    allHeight = 0
    for frame in @frames
      allX += frame.x
      allY += frame.y
      allWidth += frame.width
      allHeight += frame.height

    length = @frames.length
    @averageFace =
      x: allX/length
      y: allY/length
      width: allWidth / length
      height: allHeight / length

  applyScale: (scale) ->
    for frame in @frames
      for key of frame
        frame[key] = Math.round(frame[key] * scale)
    @

  probability: ->
    @certainty = 1 - @emptyFrames() / @frames.length

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
        y: Math.round(frame.y + (frame.height/5*3.1))
        height: Math.round(frame.height/2)
      frame.mouth.center =
        x: Math.round frame.mouth.x + frame.mouth.width/2
        y: Math.round frame.mouth.y + frame.mouth.height/2
    @frames

  findClosestFaceIn: (frame) ->
    face = @getLatestFace()
    sorted = frame.sort (a, b) =>
      @distance(a, face) - @distance(b, face)

    sorted

  distance: (obj1, obj2) ->
    Math.sqrt(Math.pow((obj1.x - obj2.x), 2) + Math.pow((obj1.y - obj2.y), 2))

  pulse: (ctx, index, amount, type) ->
    mouth = @frames[index].mouth

    ctx.fillStyle = 'rgba(255, 255, 255, 1.0)'
    ctx.beginPath()
    minWidth = mouth.width/3.5
    maxWidth = mouth.width/2
    # pulseAmount = Math.max(minWidth * amount * 1.5, minWidth)
    if amount < 0.3
      pulseAmount = 0
    else
      amount = (amount - 0.3) / (1.0 - 0.3)
      pulseAmount = minWidth + maxWidth * amount
    pulseAmount = Math.min(maxWidth * 0.9, pulseAmount)
    ctx.arc(mouth.center.x, mouth.center.y, pulseAmount, 0, 2 * Math.PI, false)

    # alpha = ((255 - audioIntensity * 255) + 100) / 200
    # log alpha

    # log type
    ctx.globalCompositeOperation = 'source-over'
    if type is 1
      ctx.fillStyle = 'white'
    else if type is 4
      ctx.fillStyle = 'black'
    else if type is 2
      ctx.fillStyle = 'black'
    else
      ctx.globalCompositeOperation = 'destination-out'
      ctx.fillStyle = 'black'

    ctx.fill()
    ctx.globalCompositeOperation = 'source-over'

  drawFace: (ctx, index, type) ->
    face = @frames[index]

    if type is 1
      ctx.fillStyle = 'black'
      ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
      ctx.fillStyle = 'white'
    else if type is 4
      ctx.fillStyle = 'black'
    else if type is 2
      ctx.fillStyle = 'black'
    else if type is 3
      ctx.globalCompositeOperation = 'destination-out'
      ctx.fillStyle = 'black'
      # ctx.fillStyle = 'rgba(5, 0, 0, 1.0)'
    ctx.fillRect(face.eyebar.x, face.eyebar.y, face.eyebar.width, face.eyebar.height)

    mouthQuarterX = face.mouth.width/4
    mouthQuarterY = face.mouth.height/4

    ctx.beginPath()
    ctx.moveTo(face.mouth.x, face.mouth.y + mouthQuarterY)
    ctx.lineTo(face.mouth.x + mouthQuarterX*3, face.mouth.y+face.mouth.height)
    ctx.lineTo(face.mouth.x + face.mouth.width, face.mouth.y+mouthQuarterY*3)
    ctx.lineTo(face.mouth.x + mouthQuarterX, face.mouth.y)
    ctx.fill()
    ctx.moveTo(face.mouth.x + mouthQuarterX*3, face.mouth.y)
    ctx.lineTo(face.mouth.x, face.mouth.y+mouthQuarterY*3)
    ctx.lineTo(face.mouth.x+mouthQuarterX, face.mouth.y+face.mouth.height)
    ctx.lineTo(face.mouth.x+face.mouth.width, face.mouth.y+mouthQuarterY)
    ctx.fill()

    ctx.globalCompositeOperation = 'source-over'


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

class CanvasPlayer
  constructor: (@canvas, @frames, @fps) ->
    # @options = @options || {}
    # @addSpacer = @options.addSpacer
    # @progress = @options.progress
    @paused = false
    @stop = false
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
    if @stop
      @options.complete()
      return @stop = !@stop
    if options.onstart?
      options.onstart()
      log 'start'
      options.onstart = null
    @timeout = 1/@fps * 1000
    @options = options || @options
    if @increment and @endFrame > @index
        @index++
    else if !@increment and @index > 0
      @index--
    else if @options.loop? and @options.loop
      log 'decrement'
      @increment = !@increment
      if @increment
        @index++
      else
        @index--
    else
      return @options.complete()

    frame = @frames[@index]
    frame = @options.preprocess(frame, @index) if @options.preprocess?
    @paintFrame(frame, @index)
    @options.addition(@context, @index) if @options.addition?
    # if @options.postprocess?
    #   log 'post process'
    #   frame = @context.getImageData 0, 0, @canvas.width, @canvas.height
    #   frame = @options.postprocess(frame)
    #   @paintFrame(frame, @index)

    setTimeout =>
      @play(options)
    , @timeout


  timestamp: ->
    if window.performance and window.performance.now then window.performance.now() else new Date().getTime()

  pause: ->
    @paused = !@paused

  paintFrame: (frame, index) ->
    @context.putImageData(frame, 0, 0)
    # @progress(index) if @progress

  cleanup: ->
    setTimeout =>
      $(@canvas).remove()
    , 300

class Converter
  constructor: (@width, options) ->
    @options = options || {}
    # @convertCanvas = document.createElement('canvas')
    # @convertCanvas.width = @canvas.width
    # @convertCanvas.height = @canvas.height
    # @convertContext = @convertCanvas.getContext('2d')
    # @files = []
    # @uploadedFiles = []
    # @formdata = new FormData()
    # @fps = @fps || 10
    # @save = false
    # @uploadedSprite
    # @gifFinished = options.gifFinished

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

  runWorker: (@frames, @complete) ->
    worker = new Worker('/workers/findFaces.js')

    framesToProcess = (frame for frame in @frames by 5)

    @foundFaces = []
    worker.addEventListener('message', (e) =>
      log "Total time took: " + (new Date().getTime() - @startedAt)/1000 + 'secs'
      log 'start processing images now'
      @foundFaces.push e.data
      if @foundFaces.length == framesToProcess.length
        window.matchedFaces = new Faces(@foundFaces, ($(document).width()/@width))
        bestBets = matchedFaces.groupFaces()
        @complete(bestBets, matchedFaces)
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

class Cropper
  constructor: (@goalDimensions) ->
    # @spacer = (@goalDimensions.height - @goalDimensions.width * 9/16) / 2

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
    @finishedFrames.push @zoomToFit @currentFace, @frameQueue.shift(), false
    if @frameQueue.length > 0
      setTimeout =>
        log @frameQueue.length
        @start()
      , 50
    else
      log 'zoomed on all frames'
      @doneCallback @finishedFrames

  zoomToFit: (face, frame, isolate) ->
    # debugger if isolate
    cropCoords = @convertFaceCoords face
    # above needs to account for aspect adjustment on zoom
    # debugger unless frame?
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

    # frame = @isolateFace(face, frame) if isolate

    frame

  isolateFace: (face, frame) ->
    log 'isolate face'
    # @goalContext.globalAlpha = 0.5
    # @goalContext.putImageData frame, 0, 0
    # @goalContext.globalAlpha = 1
    # img = @goalCanvas.toDataURL()

    center =
      x: frame.width / 2
      # y: frame.height / 2.7
      y: frame.height / 2

    face =
      x: Math.round center.x - frame.width/8
      y: Math.round center.y - frame.width/14
      width: Math.round frame.width/5
      height: Math.round frame.width/3.4
    @goalContext.globalCompositeOperation = 'destination-in'
    # @goalContext.globalCompositeOperation = 'multiply'
    # @goalContext.fillRect(face.x, face.y, face.width, face.height)
    @drawEllipseByCenter(@goalContext, center.x, center.y, face.width, face.height)
    @goalContext.fill()

    # @goalContext.globalCompositeOperation = 'multiply'
    # frame = @goalContext.getImageData 0, 0, @goalCanvas.width, @goalCanvas.height
    # @goalContext.putImageData frame, 0, 0


    frame = @goalContext.getImageData 0, 0, @goalCanvas.width, @goalCanvas.height
    process.cbrFilter frame
    # frame = @makeTransparent frame, face.width
    # idata = frame.data
    # for pixel, index in idata
    #   r = idata[index]
    #   g = idata[index+1]
    #   b = idata[index+2]

  drawEllipseByCenter: (ctx, cx, cy, w, h) ->
    @drawEllipse(ctx, cx - w/2.0, cy - h/2.0, w, h)

  drawEllipse: (ctx, x, y, w, h) ->
    kappa = .5522848
    ox = (w / 2) * kappa
    oy = (h / 2) * kappa
    xe = x + w
    ye = y + h
    xm = x + w / 2
    ym = y + h / 2
    ctx.beginPath()
    ctx.moveTo(x, ym)
    ctx.bezierCurveTo(x, ym - oy, xm - ox, y, xm, y)
    ctx.bezierCurveTo(xm + ox, y, xe, ym - oy, xe, ym)
    ctx.bezierCurveTo(xe, ym + oy, xm + ox, ye, xm, ye)
    ctx.bezierCurveTo(xm - ox, ye, x, ym + oy, x, ym)
    ctx.closePath()
    ctx.stroke()


  makeTransparent: (frame, width) ->
    targetWidth = 175
    frameWidth = frame.width
    frameHeight = frame.height
    midHeight = frameHeight/2
    midWidth = frameWidth/2
    idata = frame.data
    center = 
      x: frame.width / 2
      y: frame.height / 2.2
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
        if Math.abs(midHeight - y) > targetWidth
          targetWidth += 40
        # targetWidth = targetWidth + Math.abs(midHeight - y) / frameHeight * targetWidth
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
      # y: Math.round (center_y - height/1.9 + @spacer)
      y: Math.round (center_y - height/1.9)
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


  # window.webcam = new VideoTrack
  #   src: webcam.src
  #   aspect: @aspect
  #   littleCanvas: true
  #   shouldDraw: false
  # @video.play(@player, null,
  #   onplaystart: =>
  #     @onStart() if @onStart?
  # )
  # setTimeout ->
  #   $(window).trigger 'click'
  # , 1000

errorCallback = (error) ->
  log("navigator.getUserMedia error: ", error)

navigator.getUserMedia(constraints, successCallback, errorCallback)

class PlayController
  constructor: ->
    @started =
      yes: true
    @setDimensions()
    @recordCanvas = @createCanvas(@displayWidth)
    @recordCtx = @createContext @recordCanvas
    @activeFaces = []

    @smallRecord = @createCanvas(720)
    # @smallRecord = @createCanvas(960)
    @smallCtx = @createContext @smallRecord

    # $('body').prepend @recordCanvas
    # $('body').prepend @smallRecord


    @recorder = new Recorder @recordCanvas
    @smallRecorder = new Recorder @smallRecord

    @video = $('#mainPlayer')[0]
    @canvas = $('#mainCanvas')[0]
    @canvas.width = @recordCanvas.width
    @canvas.height = @recordCanvas.height
    @ctx = @canvas.getContext '2d'

  init: ->
    $(window).on 'click', =>
      $('h1').remove()
      @startPlayer()

  startPlayer: ->
    # @video.currentTime = 121
    @video.play()
    @webcam = $('#webcam')[0]
    @webcam.src = webcam.src
    @drawWebcam()

    @video.addEventListener 'timeupdate', (e) =>
      @checkTime(e)
      # @gameTime(e)

  replay: ->
    @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
    @started =
      yes: true
    @video.currentTime = 0
    @video.play()


  drawWebcam: =>
    @recordCtx.drawImage(@webcam,0,0, @recordCanvas.width, @recordCanvas.height)
    @smallCtx.drawImage(@webcam,0,0, @smallRecord.width, @smallRecord.height)

    if @recordingComplete
      webcam.stop()
    else
      requestAnimationFrame =>
        @drawWebcam()


  checkTime: (e) ->
    time = Math.floor @video.currentTime
    if (time) is 2
      @recordWebcam()
    # if (time) is 21
    #   @playback('raw') unless @started.raw?
    if (time) is 12
      @playback('xFrames') unless @started.xFrames?
    if (time) is 28
      log 'stop player'
      # @cPlayer.stop = true
      @smoker.stopIn = 20
    if (time) is 32
      @playback('firstFace') unless @started.firstFace?
    # if (time) is 49
    #   log 'stop player'
    #   @cPlayer.stop = true
    if (time) is 37
      @playback('secondFace') unless @started.secondFace?
    if (time) is 46
      @playback('xFrames2') unless @started.xFrames2?
    if (time) is 52
      log 'stop player'
      @cPlayer.stop = true
    if (time) is 54
      @playback('xFrames3') unless @started.xFrames3?
    if (time) is 59
      log 'stop player'
      @cPlayer.stop = true
    if (time) is 61
      @ctx.putImageData(@smoker.xFrames3[9], 0, 0)

  gameTime: (e) ->
    time = Math.floor @video.currentTime
    # log time

    if (time) is 127
      @recordWebcam()
    # if (time) is 21
    #   @playback('raw') unless @started.raw?
    if (time) is 142
      @playback('firstFace') unless @started.firstFace?
    if (time) is 149
      @playback('secondFace') unless @started.secondFace?
    if (time) is 155
      @playback('xFrames') unless @started.xFrames?
    if (time) is 168
      log 'stop player 1'
      @smoker.stopIn = 20
    if (time) is 174
      @playback('xFrames2') unless @started.xFrames2?
    if (time) is 187
      @cPlayer.stop = true
    if (time) is 192
      @playback('xFrames3') unless @started.xFrames3?
    if (time) is 197
      log 'stop player'
      @cPlayer.stop = true
    if (time) is 200
      @ctx.putImageData(@smoker.xFrames3[9], 0, 0)

  playback: (segment) ->
    # debugger if segment is 'alphaFace'
    log 'play ' + segment
    @started[segment] = true
    segment = @smoker.segments[segment]
    log 'playing'
    if segment?
      @cPlayer = new CanvasPlayer @canvas, segment.frames, 15 #@smoker.fps
      @cPlayer.play
        loop:       segment.loop
        preprocess: segment.preprocess
        postprocess: segment.postprocess
        onstart: segment.start
        addition: segment.addition
        complete: =>
          @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
          log 'done playing'
          segment.complete() if segment.complete?
    else
      log 'segment was not finished'


  recordWebcam: ->
    return if @smoker?
    secs = 2
    unless @recorder.started
      log 'start recording'
      @smoker = new Smoker(@recordCanvas, @recordCtx, @)

      @recorder.record secs, 30,
        complete: =>
          log 'done recording'
          @smoker.setFrames @recorder.capturedFrames.slice(0), @recorder.fps
          @startProcessing @recorder.capturedFrames, @recorder.fps
          @recordingComplete = true

    unless @smallRecorder.started
      @smallRecorder.record secs, 30,
        complete: =>
          @smoker.setSmall @smallRecorder.capturedFrames
          @smoker.findFaces()
          @recordingComplete = true
          log 'now find faces'
          @smallRecorder = null

  startProcessing: (frames, fps) ->
    frames = frames.slice(0)
    @recorder.capturedFrames = null
    processor = new Processor frames, null, fps
    faces = processor.
    bnwFrames = processor.blackandwhite
      complete: (bnwFrames) =>
        @smoker.setBNW(bnwFrames)
        bnwFrames = null

  findFaces: ->
    converter = new Converter @recorder.canvas,
                        @recorder.capturedFrames,
                        @recorder.fps,
                        null,
                        converted: ->
    converter.runWorker()

  setDimensions: (canvas) ->
    # @video = @video || $('video')[0]

    @displayWidth = $(document).width()
    @displayHeight = $(document).height()

    # videoHeight = @displayWidth * 9/16
    # log videoHeight
    # spacer = (@displayHeight - videoHeight) / 2
    # log spacer

    # $(@video).css('margin-top', (@displayHeight - videoHeight) / 2)

  createCanvas: (width) ->
    canvas = document.createElement 'canvas'
    canvas.height = Math.ceil width * 9/16
    canvas.width = width
    canvas

  createContext: (canvas) ->
    context = canvas.getContext '2d'


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

window.process =
  cbrFilter: (frame) ->
    idata = frame.data

    for pixel, index in idata by 4
      r = idata[index]
      g = idata[index+1]
      b = idata[index+2]

      y  = 0.299 * r + 0.587 * g + 0.114 * b
      cB = 128 + (-0.169 * r + 0.331 * g + 0.5 * b)
      cR = 128 + (0.5 * r - 0.419 * g - 0.081 * b)

      if cR > 80 && cR > 127 && cB > 137 && cB < 165 && y > 26 && y < 226
      # if r > 100
       idata[index]   = 255
       idata[index+1] = 255
       idata[index+2] = 255
       if audioIntensity?
         alpha = ((255 - audioIntensity * 255) + 100) / 200
       else
         window.audioIntensity = 0
       idata[index+3] = alpha
      else
       idata[index+3] = 0

    frame.data = idata
    frame

class Processor
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
        options.complete(newFrames)
        # @addSequence()
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

class Recorder
  constructor: (@canvas) ->
    @capturedFrames = []
    @context = @canvas.getContext('2d')
    @width = @canvas.width
    @height = @canvas.height
    @started = false

  reset: ->
    @capturedFrames = []


  record: (seconds, @fps, @options) ->
    @started = true
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

class Smoker
  constructor: (@canvas, @context, @player) ->
    @frames = []
    @smallFrames = []
    @bnwFrames = []
    @segments = {}
    @xFrames = []
    @xFrames2 = []
    @xFrames3 = []


  setBNW: (frames) ->
    @bnwFrames = frames.slice(0)
    @segments.xFrames =
      frames: @bnwFrames
      loop: true
      addition: (ctx, index) =>
        @pulseMouths(ctx, index, 1)
      start: =>
        new soundAnalyzer(@player).playSound()
    if @faces? #and @xFrames.length is 0
      # log 'bnw setup zooms'
      @setupZooms()
      # @processXFrames(null, null, 1)

  setFrames: (frames, fps) ->
    @frames = frames.slice(0)
    @width = @frames[0].width
    @height = @frames[0].height
    @segments.raw =
      frames: @frames
      # preprocess: @cbrFilter
    @fps = fps

  setSmall: (frames) ->
    @smallFrames = frames.slice(0)

  findFaces: ->
    converter = new Converter(@smallFrames[0].width)
    converter.runWorker(@smallFrames, (faces, faceCollection) =>
      @faceCollection = faceCollection
      @faces = @faceCollection.sortByCertainty(faces)
      @faceCollection.applyScale(@frames[0].width/@smallFrames[0].width)
      @faceCollection.fillInBlanks(3)
      @smallFrames = []
      @frames = []
      converter = null
      @player.recorder = null
      @player.smallRecorder = null
      log 'got all the faces', @faces
      if @bnwFrames.length > 0 #and @xFrames.length is 0
        # @processXFrames(null, null, 1)
        # log 'findFaces setup zooms'
        @setupZooms()
      # @segments.rawRects =
      #   frames: @frames
      #   addition: (ctx, index) =>
      #     @drawFaces(ctx, index)
    )


  processXFrames: (inProcess, index, type) ->
    inProcess = inProcess or @bnwFrames.slice(0)
    index = index or 0
    frame = inProcess.shift()
    @context.putImageData(frame, 0, 0)
    @drawFaces @context, index, type
    if type is 1
      @xFrames.push @context.getImageData 0, 0, @canvas.width, @canvas.height
    else if type is 2
      @xFrames2.push @context.getImageData 0, 0, @canvas.width, @canvas.height
    else
      @xFrames3.push @context.getImageData 0, 0, @canvas.width, @canvas.height

    if inProcess.length > 0
      setTimeout =>
        log index
        index++
        @processXFrames(inProcess, index, type)
      , 50
    else
      log 'done with processXFrames ' + type
      # if type is 1
      #   @segments.xFrames =
      #     frames: @xFrames
      #     loop: true
      #     addition: (ctx, index) =>
      #       @pulseMouths(ctx, index, 1)
      #     # postprocess: @pulseBlack
      #     # preprocess: @pulseBlack
      #   # @setupZooms()
      #   @processXFrames(null, null, 2)

      # else if type is 2
      if type is 2
        @segments.xFrames2 =
          frames: @xFrames2
          loop: true
          addition: (ctx, index) =>
            @pulseMouths(ctx, index, 2)
          # postprocess: @pulseBlack
          # preprocess: @pulseBlack
        @processXFrames(null, null, 3)
        # @setupZooms()
      else
        @segments.xFrames3 =
          frames: @xFrames3
          loop: true
          addition: (ctx, index) =>
            @pulseMouths(ctx, index, 3)
          # postprocess: @pulseBlack
          # preprocess: @pulseBlack


  setupZooms: ->
    if @faces.length > 0
      zoomFaces = []
      # TODO @faceCollection.threeBestFaces()
      for i in [0..2]
        if i < @faces.length
          zoomFaces[i] = @faces[i]
        else
          zoomFaces[i] = @faces[0]
      @zoomOnFace(zoomFaces[0], (frames) =>
        log 'zoom ready'
        index = 0
        # until frames.length is 260
        #   frames.push frames[index]
        #   index++
        #   if index > frames.length - 1
        #     index = 0
        @segments.firstFace =
          frames: frames
          # loop: true
          # addition: @pulseMouths
          # preprocess: @alphaInOut
          addition: @fadeInOut
          # complete: =>
          #   @segments.firstFace = null
        @getSecondFace(zoomFaces)
      )
    else
      log 'no faces to zoom on'

  zoomOnFace: (face, complete) ->
    return if !face.frames? or face.frames.length < 7
    log 'zoomonface'

    frames = @bnwFrames

    # centerFace = face.frames[6]
    centerFace = face.getAverageFace()
    # TODO face.averageFace
    crop = new Cropper
      width: @width
      height: @height
    crop.queue(centerFace, frames)
    crop.start (frames) =>
      console.log 'done running cropper'
      complete(frames)
      crop = null
      frames = null

  getSecondFace: (zoomFaces) ->
    @zoomOnFace(zoomFaces[1], (frames) =>
      log 'got second face'
      @segments.secondFace =
        frames: frames
        addition: @fadeInOut
        # complete: =>
        #   @segments.secondFace = null
        #   setTimeout =>
        #     log 'second face done, now process xFrames3'
        #     @processXFrames(null, null, 3)
        #   , 500
      # @getThirdFace(zoomFaces)
      @processXFrames(null, null, 2)
    )

  getThirdFace: (zoomFaces) ->
    @zoomOnFace(zoomFaces[2], (frames) =>
      @segments.thirdFace =
        frames: frames
        # addition: @fadeInOut
        preprocess: @cbrFilter

      @processXFrames(null, null, 1)
      # @getAlphaFace()
    )

  getAlphaFace: ->
    log 'get alpha face'
    face = @faces[0].frames[8]
    # frame = @bnwFrames.slice(8, 9)[0]
    frame = @frames.slice(8, 9)[0]

    crop = new Cropper
      width: @width
      height: @height

    @alphaFace = crop.zoomToFit(face, frame, true)
    @alphaFrames = []
    for i in [0..190]
      @alphaFrames.push @alphaFace
    @segments.alphaFace =
      frames: @alphaFrames
      # preprocess: @cbrFilter
      # addition: @drawAlphaFace

  drawFaces: (ctx, index, type) ->
    if type is 1
      @activeFaces = @faces.slice(0, 1)
    if type is 2
      @activeFaces = @faces.slice(0, 3)
    if type is 3
      @activeFaces = @faces
    if @activeFaces.length > 0
      for face in @activeFaces
        face.drawFace ctx, index, type

  pulseBlack: (frame) =>
    idata = frame.data
    trans = Math.floor (255 - audioIntensity * 255) + 100

    for pixel, index in idata by 4
      r = idata[index]
      g = idata[index+1]
      # b = idata[index+2]

      # total = r + g + b
      # debugger
      # if r is 5 and g is 0
      if r is 5 and g is 0
        # c = trans * 0.5
        # idata[index] = c
        # idata[index+1] = c
        # idata[index+2] = c
        idata[index+3] = 0
        # debugger

    frame.data = idata
    frame

  cbrFilter: (frame) ->
    # inProcess = inProcess or @frames.slice(0)
    # index = index or 0
    # frame = inProcess.shift()
    process.cbrFilter frame

  fadeInOut: (ctx, index) ->
    # totalFrames = totalFrames or 90
    if index < 30
      alpha = 1 - index/30
      ctx.fillStyle = 'rgba(0, 0, 0,' + alpha + ')'
    else if index > 30
      alpha = index%30/30
      ctx.fillStyle = 'rgba(0, 0, 0,' + alpha + ')'

    ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)

  alphaInOut: (frame, index) ->
    if index < 45
      alpha = 255 * (1 - index/45)
    else if index > 45
      alpha = 255 * (index%45/45)

    log index
    log alpha
    alpha = Math.floor alpha

    idata = frame.data
    for pixel, index in idata
      idata[index+3] = alpha

    frame.data = idata
    frame

  pulseMouths: (ctx, index, type) =>
    @type = type
    if @faces.length > 0
      if type is 1
        face = @faces[0]
        faces = [face]
        if @stopIn?
          type = 4
          @type = type
          @stopIn--
          log 'stopIn', @stopIn
          if @stopIn % 2 is 0
            ctx.fillStyle = 'rgba(0, 0, 0, 0.8)'
            ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
          else
            ctx.fillStyle = 'rgba(0, 0, 0, 0.6)'
            ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
          if @stopIn < 1
            log 'stop for real ' + type
            @stopIn = null
            @player.cPlayer.stop = true
        else
          ctx.fillStyle = 'black'
          ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
        face.drawFace(ctx, index, type)
      else if type is 2
        faces = @faces.slice(0, 3)
        # if @stopIn?
        #   @stopIn--
        #   if @stopIn < 1
        #     log 'stop for real ' + type
        #     @stopIn = null
        #     @player.cPlayer.stop = true
      else
        faces = @faces
      for face in faces
        face.pulse ctx, index, audioIntensity, type

  drawAlphaFace: (ctx, index) =>
    frame =
      width: ctx.canvas.width
      height: ctx.canvas.height

    # face =
    #   eyebar:
    #     x: frame.width / 2.5
    #     y: frame.height / 2.3
    #     width: frame.width / 4.5
    #     height: frame.height / 8



    # # ctx.globalCompositeOperation = 'destination-out'
    # ctx.fillStyle = 'black'

    # ctx.fillRect(face.eyebar.x, face.eyebar.y, face.eyebar.width, face.eyebar.height)



$ ->
  window.video = $('video')[0]
  window.audioIntensity = 0.5
  init = ->
    window.player = new PlayController()
    player.init()

    # start drawing webcam to player's record canvases

  init()




  # window.faces = []
  # window.player = new Player [
  #     camSequence
  #   ,
  #     testSequence
  #   ,
  #     playbackCamSequence
  #   ,
  #     new VideoTrack
  #       src: '/assets/videos/short.mov'
  #       aspect: 16/9
  #   ,
  #     playbackCamSequence
  # ]

  $(window).resize ->
    player.setDimensions()
  #   # player.tracks[player.currentTrack].setDimensions()

  # $(window).on 'click', ->
  #   $('h1').remove()
  #   video.play()
    # player.play()
