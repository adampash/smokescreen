class window.Cropper
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
        @start()
      , 75
    else
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

    frame = @isolateFace(face, frame) if isolate

    frame

  isolateFace: (face, frame) ->
    log 'isolate face'
    @goalContext.globalAlpha = 0.5
    @goalContext.putImageData frame, 0, 0
    @goalContext.globalAlpha = 1
    # img = @goalCanvas.toDataURL()

    center =
      x: frame.width / 2
      # y: frame.height / 2.7
      y: frame.height / 2

    face =
      x: Math.round center.x - frame.width/8
      y: Math.round center.y - frame.width/14
      width: Math.round frame.width/5.5
      height: Math.round frame.width/3.4
    # @goalContext.globalCompositeOperation = 'destination-in'
    # @goalContext.fillRect(face.x, face.y, face.width, face.height)
    # @drawEllipseByCenter(@goalContext, center.x, center.y, face.width, face.height)

    # @goalContext.fill()

    frame = @goalContext.getImageData 0, 0, @goalCanvas.width, @goalCanvas.height
    frame = @makeTransparent frame, face.width
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

