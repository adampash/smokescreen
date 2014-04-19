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

