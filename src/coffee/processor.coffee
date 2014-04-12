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
