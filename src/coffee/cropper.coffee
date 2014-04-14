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

