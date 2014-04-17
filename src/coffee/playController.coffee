class window.PlayController
  constructor: ->
    @started =
      yes: true
    @setDimensions()
    @recordCanvas = @createCanvas(@displayWidth)
    @recordCtx = @createContext @recordCanvas

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
      @video.play()
      @webcam = $('#webcam')[0]
      @webcam.src = webcam.src
      @drawWebcam()

    @video.addEventListener 'timeupdate', (e) =>
      @checkTime(e)
      # @gameTime(e)

  drawWebcam: =>
    @recordCtx.drawImage(@webcam,0,0, @recordCanvas.width, @recordCanvas.height)
    @smallCtx.drawImage(@webcam,0,0, @smallRecord.width, @smallRecord.height)

    if @recordingComplete
      webcam.stop()
    else
      requestAnimationFrame =>
        @drawWebcam()


  checkTime: (e) ->
    time = @video.currentTime
    # log time
    if Math.floor(time) is 2
      @recordWebcam()
    if Math.floor(time) is 21
      @playback('raw') unless @started.raw?
    if Math.floor(time) is 39
      @playback('firstFace') unless @started.firstFace?
    if Math.floor(time) is 52
      @playback('xFrames') unless @started.xFrames?
    # if Math.floor(time) is 49
    #   @playback('secondFace') unless @started.secondFace?
    if Math.floor(time) is 61
      @playback('thirdFace') unless @started.thirdFace?
    if Math.floor(time) is 69
      @playback('alphaFace') unless @started.alphaFace?

  gameTime: (e) ->
    time = @video.currentTime
    if Math.floor(time) is 127
      @recordWebcam()
    # if Math.floor(time) is 21
    #   @playback('raw') unless @started.raw?
    if Math.floor(time) is 180
      @playback('firstFace') unless @started.firstFace?
    if Math.floor(time) is 187
      @playback('xFrames') unless @started.xFrames?
    if Math.floor(time) is 197
      @playback('secondFace') unless @started.secondFace?
    if Math.floor(time) is 204
      @playback('thirdFace') unless @started.thirdFace?
    if Math.floor(time) is 210
      @playback('alphaFace') unless @started.thirdFace?

  playback: (segment) ->
    # debugger if segment is 'alphaFace'
    log 'play ' + segment
    @started[segment] = true
    segment = @smoker.segments[segment]
    log 'playing'
    if segment?
      window.cPlayer = new CanvasPlayer @canvas, segment.frames, 20 #@smoker.fps
      cPlayer.play
        preprocess: segment.preprocess
        postprocess: segment.postprocess
        onstart: segment.start
        addition: segment.addition
        complete: =>
          @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
          log 'done playing'
    else
      log 'segment was not finished'


    # @ctx.putImageData
    # @ctx.fillStyle = "black"
    # @ctx.fillRect(10, 10, 300, 200)

  recordWebcam: ->
    secs = 3
    unless @recorder.started
      log 'start recording'
      @smoker = new Smoker(@recordCanvas, @recordCtx)

      @recorder.record secs, 30,
        complete: =>
          log 'done recording'
          @smoker.setFrames @recorder.capturedFrames.slice(0), @recorder.fps
          @startProcessing @recorder.capturedFrames.slice(0), @recorder.fps
          @recordingComplete = true

    unless @smallRecorder.started
      @smallRecorder.record secs, 30,
        complete: =>
          @smoker.setSmall @smallRecorder.capturedFrames
          @smoker.findFaces()
          @recordingComplete = true
          log 'now find faces'

  startProcessing: (frames, fps) ->
    frames = frames.slice(0)
    window.processor = new Processor frames, null, fps
    faces = processor.
    bnwFrames = processor.blackandwhite
      complete: (bnwFrames) =>
        @smoker.setBNW(bnwFrames)

  findFaces: ->
    window.converter = new Converter @recorder.canvas,
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

