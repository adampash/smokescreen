(function() {
  var CanvasPlayer, Converter, Cropper, Face, Faces, PlayController, Processor, Recorder, Smoker, constraints, errorCallback, successCallback,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $(function() {
    window.dev = true;
    window.log = function(args) {
      if (true) {
        return console.log.apply(console, arguments);
      }
    };
    if (dev) {
      return $('body').append($('<script src="//localhost:35729/livereload.js"></script>'));
    }
  });

  $(function() {
    return window.Player = (function() {
      function Player(tracks) {
        this.tracks = tracks;
        this.currentTrack = 0;
        this.videoPlaying = false;
        this.setDimensions();
      }

      Player.prototype.setDimensions = function(canvas) {
        this.displayWidth = $(document).width();
        this.displayHeight = $(document).height();
        return this.tracks[this.currentTrack].setDimensions();
      };

      Player.prototype.play = function(trackIndex) {
        log('play');
        if (trackIndex != null) {
          this.currentTrack = trackIndex;
          return this.queue(this.tracks[trackIndex]);
        } else if (this.currentTrack < this.tracks.length) {
          return this.queue(this.tracks[this.currentTrack]);
        }
      };

      Player.prototype.nextTrack = function() {
        this.currentTrack++;
        return this.play();
      };

      Player.prototype.prevTrack = function() {
        this.currentTrack--;
        return this.play();
      };

      Player.prototype.queue = function(track) {
        log('queue', track);
        return track.play(this, (function(_this) {
          return function() {
            return _this.nextTrack();
          };
        })(this));
      };

      Player.prototype.addTrack = function(track) {
        this.tracks.push(track);
        if (this.currentTrack === this.tracks.length - 1) {
          return this.play(this.tracks.length - 1);
        }
      };

      return Player;

    })();
  });

  $(function() {
    return window.Sequence = (function() {
      function Sequence(options) {
        this.drawSequence = __bind(this.drawSequence, this);
        this.setDimensions = __bind(this.setDimensions, this);
        var _this;
        this.options = options;
        this.type = 'sequence';
        this.src = options.src;
        this.aspect = options.aspect;
        this.duration = options.duration;
        if (options.onStart != null) {
          this.onStart = options.onStart;
        }
        this.canvas = this.createCanvas();
        this.canvas.id = new Date().getTime();
        this.context = this.createContext(this.canvas);
        this.canvases = [];
        this.canvases.push(this.canvas);
        this.playing = false;
        _this = this;
        $(window).resize((function(_this) {
          return function() {
            if (_this.playing) {
              return _this.setDimensions();
            }
          };
        })(this));
      }

      Sequence.prototype.setDimensions = function() {
        if (this.player != null) {
          this.canvases.map(function(canvas) {
            canvas.width = this.player.displayWidth;
            return canvas.height = this.player.displayHeight;
          });
          if (this.video) {
            return this.video.setDimensions();
          }
        }
      };

      Sequence.prototype.play = function(player, callback) {
        $('body').append(this.canvas);
        log('playSequence');
        this.playing = true;
        this.player = player;
        this.callback = callback;
        this.setDimensions();
        if (this.src != null) {
          if (this.src === 'webcam') {
            log('it is a webcam');
            this.src = webcam.src;
            this.video = new VideoTrack({
              src: this.src,
              aspect: this.aspect,
              littleCanvas: true,
              shouldDraw: false
            });
            this.video.play(this.player, null, {
              onplaystart: (function(_this) {
                return function() {
                  if (_this.onStart != null) {
                    return _this.onStart();
                  }
                };
              })(this)
            });
            this.startSequence();
            return this.canvases.push(this.video);
          } else if (this.src === 'CanvasPlayer') {
            this.video = new CanvasPlayer(this.canvas, this.options.frames || window.recorder.capturedFrames, this.options.fps || window.recorder.fps, {
              addSpacer: this.options.addSpacer || false,
              progress: (function(_this) {
                return function(index) {
                  if (_this.drawAnimation != null) {
                    return _this.drawAnimation(index);
                  }
                };
              })(this)
            });
            return this.video.play({
              player: this.player,
              ended: (function(_this) {
                return function() {
                  return _this.ended();
                };
              })(this)
            });
          } else {
            this.video = new VideoTrack({
              src: this.src,
              aspect: this.aspect
            });
            return this.video.play(this.player, null, {
              onplaystart: (function(_this) {
                return function() {
                  return _this.startSequence();
                };
              })(this)
            });
          }
        } else {
          return this.startSequence();
        }
      };

      Sequence.prototype.startSequence = function() {
        this.sequenceStart = new Date();
        return this.drawSequence();
      };

      Sequence.prototype.drawSequence = function() {
        var elapsed;
        elapsed = (new Date() - this.sequenceStart) / 1000;
        this.drawAnimation(this, elapsed);
        if (elapsed < this.duration) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawSequence();
            };
          })(this));
        } else {
          log('end sequence');
          return this.ended();
        }
      };

      Sequence.prototype.cleanup = function() {
        setTimeout((function(_this) {
          return function() {
            return $(_this.canvas).remove();
          };
        })(this), 300);
        return this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
      };

      Sequence.prototype.createCanvas = function() {
        var canvas;
        canvas = document.createElement('canvas');
        return canvas;
      };

      Sequence.prototype.createContext = function(canvas) {
        var context;
        return context = canvas.getContext('2d');
      };

      return Sequence;

    })();
  });

  $(function() {
    window.testSequence = new Sequence({
      type: 'sequence',
      src: '/assets/videos/short.mov',
      aspect: 16 / 9,
      duration: 5
    });
    testSequence.drawAnimation = function(context, elapsed) {
      var x, y;
      x = elapsed * 100;
      y = elapsed * 100;
      this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.context.fillStyle = 'rgba(0, 100, 0, 0.4)';
      this.context.fillOpacity = 0.1;
      return this.context.fillRect(x, y, 400, 400);
    };
    return testSequence.ended = function() {
      if (this.callback != null) {
        this.callback();
      }
      return this.cleanup();
    };
  });

  $(function() {
    return window.VideoTrack = (function() {
      function VideoTrack(options) {
        this.setupVideoListeners = __bind(this.setupVideoListeners, this);
        this.drawVideo = __bind(this.drawVideo, this);
        this.type = 'video';
        this.src = options.src;
        this.aspect = options.aspect;
        this.canvas = this.createCanvas();
        this.canvas.id = new Date().getTime();
        this.context = this.createContext(this.canvas);
        this.videoPlaying = false;
        this.shouldDraw = options.shouldDraw || true;
        if (options.littleCanvas != null) {
          this.littleCanvas = this.createCanvas();
          this.littleCanvas.width = 960;
          this.littleCanvas.height = 540;
          this.littleContext = this.createContext(this.littleCanvas);
        }
      }

      VideoTrack.prototype.play = function(player, callback, options) {
        log('playVideo');
        this.player = player;
        this.callback = callback;
        if (options) {
          if (options.onplaystart != null) {
            this.onplaystart = options.onplaystart;
          }
        }
        $('body').prepend(this.canvas);
        this.setDimensions();
        this.video = document.createElement('video');
        this.video.src = this.src;
        this.setupVideoListeners(this.video);
        return this.video.play();
      };

      VideoTrack.prototype.setDimensions = function() {
        if (this.player != null) {
          this.canvas.width = this.player.displayWidth;
          return this.canvas.height = this.player.displayHeight;
        }
      };

      VideoTrack.prototype.drawVideo = function() {
        var height, spacer;
        height = this.player.displayWidth / this.aspect;
        spacer = (this.player.displayHeight - height) / 2;
        if (this.littleCanvas != null) {
          window.spacer = spacer;
        }
        this.context.drawImage(this.video, 0, spacer, this.player.displayWidth, height);
        if (this.littleCanvas != null) {
          this.littleContext.drawImage(this.video, 0, 0, this.littleCanvas.width, this.littleCanvas.height);
        }
        if (this.videoPlaying) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawVideo();
            };
          })(this));
        }
      };

      VideoTrack.prototype.setupVideoListeners = function(video) {
        video.addEventListener('playing', (function(_this) {
          return function(event) {
            if (_this.onplaystart != null) {
              _this.onplaystart();
            }
            _this.videoPlaying = true;
            if (_this.shouldDraw) {
              return _this.drawVideo();
            }
          };
        })(this));
        return video.addEventListener('ended', (function(_this) {
          return function(event) {
            if (_this.video === event.srcElement) {
              _this.videoPlaying = false;
              _this.cleanup();
              if (_this.callback != null) {
                return _this.callback();
              }
            }
          };
        })(this));
      };

      VideoTrack.prototype.cleanup = function() {
        return setTimeout((function(_this) {
          return function() {
            return $(_this.canvas).remove();
          };
        })(this), 300);
      };

      VideoTrack.prototype.createCanvas = function() {
        var canvas;
        canvas = document.createElement('canvas');
        return canvas;
      };

      VideoTrack.prototype.createContext = function(canvas) {
        var context;
        return context = canvas.getContext('2d');
      };

      return VideoTrack;

    })();
  });

  window.soundAnalyzer = (function() {
    function soundAnalyzer(player) {
      this.player = player;
      this.analyze = __bind(this.analyze, this);
      this.all = 0;
      this.counter = 0;
      this.low = 1000;
      this.high = 4000;
    }

    soundAnalyzer.prototype.playSound = function(soundURL) {
      var $intensity, audioContext;
      this.shouldAnalyze = true;
      soundURL = soundURL || "/assets/audio/AWOBMOLGQUIET.mp3";
      console.log('playing sound: ' + soundURL);
      $('body').append('<audio id="poem" autoplay="autoplay"><source src="' + soundURL + '" type="audio/mpeg" /><embed hidden="true" autostart="true" loop="false" src="' + soundURL + '" /></audio>');
      audioContext = new (window.AudioContext || window.webkitAudioContext)();
      this.audioElement = document.getElementById("poem");
      this.analyzer = audioContext.createAnalyser();
      this.analyzer.fftSize = 64;
      this.frequencyData = new Uint8Array(this.analyzer.frequencyBinCount);
      this.audioElement.addEventListener("canplay", (function(_this) {
        return function() {
          var source;
          source = audioContext.createMediaElementSource(_this.audioElement);
          console.log('can play');
          source.connect(_this.analyzer);
          return _this.analyzer.connect(audioContext.destination);
        };
      })(this));
      this.audioElement.addEventListener('ended', (function(_this) {
        return function() {
          _this.shouldAnalyze = false;
          log('average level: ' + _this.all / _this.counter);
          log('audio ended');
          _this.audioElement.removeEventListener('playing', _this.analyze, false);
          return $('#poem').remove();
        };
      })(this), false);
      this.audioElement.addEventListener('playing', this.analyze, false);
      return $intensity = $("#intensity");
    };

    soundAnalyzer.prototype.analyze = function() {
      var frequency, magnitude, _i, _len, _ref;
      this.analyzer.getByteFrequencyData(this.frequencyData);
      magnitude = 0;
      _ref = this.frequencyData;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frequency = _ref[_i];
        magnitude += frequency;
      }
      this.high = Math.max(this.high, magnitude);
      this.low = Math.min(this.low, magnitude);
      magnitude = (magnitude - 2000) / (this.high - 2000);
      window.audioIntensity = Math.max(Math.min(magnitude, 1), 0);
      if (this.shouldAnalyze) {
        return setTimeout(this.analyze, 10);
      }
    };

    return soundAnalyzer;

  })();

  Faces = (function() {
    function Faces(faces, scale) {
      this.scale = scale;
      if (faces.length != null) {
        this.allFaces = this.flatten(faces);
      } else {
        this.allFaces = faces || [];
      }
      this.calculateAvgFace();
      this.facesByFrames = faces;
    }

    Faces.prototype.sortByCertainty = function(faces) {
      faces.sort(function(a, b) {
        return b.certainty - a.certainty;
      });
      return faces;
    };

    Faces.prototype.groupFaces = function(frames, faces) {
      var firstFace, frameNumber, i, thisFace;
      if (frames == null) {
        this.removeAnomolies();
      }
      frames = frames || this.reconstruct();
      faces = faces || [];
      frameNumber = frameNumber || 0;
      thisFace = new Face();
      faces.push(thisFace);
      firstFace = false;
      i = 0;
      while (!(firstFace || i > frames.length)) {
        if ((frames[i] != null) && frames[i].length) {
          firstFace = frames[i][0];
          frames[i].splice(0, 1);
        } else {
          thisFace.frames.push(void 0);
          i++;
        }
      }
      thisFace.frames.push(firstFace);
      if (!this.empty(frames)) {
        thisFace.findRelatives(frames);
      }
      if (this.empty(frames)) {
        faces = this.verifyFrameNumbers(faces, frames.length);
        faces = this.removeProbableFalse(faces);
        this.faceMap = faces;
        return faces;
      } else {
        return this.groupFaces(frames, faces);
      }
    };

    Faces.prototype.applyScale = function(scale) {
      var face, _i, _len, _ref;
      _ref = this.faceMap;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        face = _ref[_i];
        face.applyScale(scale);
      }
      return this.faceMap;
    };

    Faces.prototype.removeProbableFalse = function(faces) {
      var face, newFaces, _i, _len;
      newFaces = [];
      for (_i = 0, _len = faces.length; _i < _len; _i++) {
        face = faces[_i];
        console.log(face.probability());
        if (face.probability() > 0.18) {
          newFaces.push(face);
        } else {
          console.log('removing ', face);
        }
      }
      return newFaces;
    };

    Faces.prototype.verifyFrameNumbers = function(faces, numFrames) {
      var fixedFaces;
      console.log('all faces should have ' + numFrames + ' frames');
      fixedFaces = faces.map(function(face) {
        if (face.frames.length < numFrames) {
          while (face.frames.length !== numFrames) {
            face.frames.push(void 0);
          }
        } else if (face.frames.length > numFrames) {
          face.frames.splice(numFrames, -1);
        }
        return face;
      });
      return fixedFaces;
    };

    Faces.prototype.empty = function(arrayOfArrays) {
      var empty, i;
      i = 0;
      empty = true;
      console.log('checking for empty');
      while (empty && i < arrayOfArrays.length) {
        if (arrayOfArrays[i].length > 0) {
          empty = false;
        }
        i++;
      }
      return empty;
    };

    Faces.prototype.prepareForCanvas = function(faces) {
      var face, frame, frames, index, _i, _j, _len, _len1, _ref;
      faces = faces || this.faceMap;
      frames = [];
      for (_i = 0, _len = faces.length; _i < _len; _i++) {
        face = faces[_i];
        _ref = face.frames;
        for (index = _j = 0, _len1 = _ref.length; _j < _len1; index = ++_j) {
          frame = _ref[index];
          if (frames[index] == null) {
            frames[index] = [];
          }
          if (frame != null) {
            frames[index].push(frame);
          }
        }
      }
      return frames;
    };

    Faces.prototype.fillInBlanks = function() {
      var face, _i, _len, _ref;
      _ref = this.faceMap;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        face = _ref[_i];
        face.fillInBlanks(3);
      }
      return this.faceMap;
    };

    Faces.prototype.removeAnomolies = function() {
      var face, goodFaces, index, newNumFaces, _i, _len, _ref;
      goodFaces = [];
      newNumFaces = 0;
      _ref = this.allFaces;
      for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
        face = _ref[index];
        if (!face.frame) {
          if (Math.abs(1 - face.width * face.height / this.avgFace) < 0.7) {
            goodFaces.push(face);
            newNumFaces++;
          }
        } else {
          goodFaces.push(face);
        }
      }
      console.log('started with ' + this.allFaces.length + ' and ending with ' + goodFaces.length);
      this.allFaces = goodFaces;
      return this.numFaces = newNumFaces;
    };

    Faces.prototype.flatten = function(faces) {
      var newFaces;
      newFaces = [];
      this.numFaces = 0;
      faces.map((function(_this) {
        return function(facesArray, index) {
          newFaces.push({
            frame: true,
            num: index
          });
          return facesArray.map(function(face) {
            _this.numFaces++;
            return newFaces.push(face);
          });
        };
      })(this));
      return newFaces;
    };

    Faces.prototype.reconstruct = function() {
      var face, facesInFrames, i, index, _i, _len, _ref;
      console.log('there are ' + this.facesByFrames.length + ' frames and ' + this.numFaces + ' faces total which adds up to ' + this.allFaces.length);
      facesInFrames = [];
      _ref = this.allFaces;
      for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
        face = _ref[index];
        if (face.frame) {
          i = 1;
          facesInFrames.push([]);
          while (typeof this.allFaces[index + i] === "object" && (this.allFaces[index + i].x != null)) {
            facesInFrames[facesInFrames.length - 1].push(this.allFaces[index + i]);
            i++;
          }
        }
      }
      return facesInFrames;
    };

    Faces.prototype.calculateAvgFace = function() {
      var totalFaceArea;
      totalFaceArea = this.allFaces.reduce(function(accumulator, face) {
        if (face.width != null) {
          return accumulator += face.width * face.height;
        } else {
          return accumulator;
        }
      }, 0);
      return this.avgFace = totalFaceArea / this.numFaces;
    };

    return Faces;

  })();

  Face = (function() {
    function Face() {
      this.frames = [];
      this.started = null;
    }

    Face.prototype.getAverageFace = function() {
      var allHeight, allWidth, allX, allY, frame, length, _i, _len, _ref;
      if (this.averageFace != null) {
        return this.averageFace;
      }
      allX = 0;
      allY = 0;
      allWidth = 0;
      allHeight = 0;
      _ref = this.frames;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        allX += frame.x;
        allY += frame.y;
        allWidth += frame.width;
        allHeight += frame.height;
      }
      length = this.frames.length;
      return this.averageFace = {
        x: allX / length,
        y: allY / length,
        width: allWidth / length,
        height: allHeight / length
      };
    };

    Face.prototype.applyScale = function(scale) {
      var frame, key, _i, _len, _ref;
      _ref = this.frames;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        for (key in frame) {
          frame[key] = Math.round(frame[key] * scale);
        }
      }
      return this;
    };

    Face.prototype.probability = function() {
      return this.certainty = 1 - this.emptyFrames() / this.frames.length;
    };

    Face.prototype.emptyFrames = function() {
      var frame, numEmpty, _i, _len, _ref;
      numEmpty = 0;
      _ref = this.frames;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        if (frame === void 0 || frame === false) {
          numEmpty++;
        }
      }
      return numEmpty;
    };

    Face.prototype.padFrames = function(padding) {
      var frame, newFrames, num, _i, _j, _len, _ref;
      newFrames = [];
      _ref = this.frames;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        newFrames.push(frame);
        for (num = _j = padding; padding <= 0 ? _j <= 0 : _j >= 0; num = padding <= 0 ? ++_j : --_j) {
          newFrames.push(void 0);
        }
      }
      return this.frames = newFrames;
    };

    Face.prototype.fillInBlanks = function(padding) {
      var frame, i, index, _i, _len, _ref;
      if (padding != null) {
        this.padFrames(padding);
      }
      i = 0;
      _ref = this.frames;
      for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
        frame = _ref[index];
        if (frame === void 0) {
          this.fillIn(index);
          i++;
        }
      }
      console.log('we had ' + i + ' frames that needed filling in');
      return this.fillInEyesAndMouth();
    };

    Face.prototype.fillIn = function(index) {
      var i, lastFrame, match;
      if (index === 0) {
        match = false;
        i = 1;
        while (!match) {
          if (this.frames[index + i] !== void 0) {
            match = this.frames[index + i];
          }
          i++;
        }
        return this.frames[index] = match;
      } else if (index === this.frames.length - 1) {
        return this.frames[index] = this.frames[index - 1];
      } else {
        lastFrame = this.frames[index - 1];
        match = false;
        i = 1;
        while (!(match || index + i >= this.frames.length)) {
          if (this.frames[index + i] !== void 0) {
            match = this.frames[index + i];
          } else {
            i++;
          }
        }
        if (match) {
          return this.fillBetween(index - 1, index + i);
        } else {
          return this.frames[index] = lastFrame;
        }
      }
    };

    Face.prototype.fillBetween = function(index1, index2) {
      var applyDiff, firstFrame, i, lastFrame, numFrames, widthDiff, xDiff, yDiff, _results;
      numFrames = index2 - index1;
      firstFrame = this.frames[index1];
      lastFrame = this.frames[index2];
      xDiff = firstFrame.x - lastFrame.x;
      yDiff = firstFrame.y - lastFrame.y;
      widthDiff = firstFrame.width - lastFrame.width;
      applyDiff = {
        x: Math.round(xDiff / numFrames),
        y: Math.round(yDiff / numFrames),
        width: Math.round(widthDiff / numFrames)
      };
      i = index1 + 1;
      _results = [];
      while (i !== index2) {
        this.frames[i] = {
          x: this.frames[i - 1].x - applyDiff.x,
          y: this.frames[i - 1].y - applyDiff.y,
          width: this.frames[i - 1].width - applyDiff.width,
          height: this.frames[i - 1].height - applyDiff.width
        };
        _results.push(i++);
      }
      return _results;
    };

    Face.prototype.findRelatives = function(frames) {
      var bestMatch, closestFaces, nextFrame;
      nextFrame = false;
      while (!(nextFrame || this.frames.length > frames.length)) {
        if ((frames[this.frames.length] != null) && frames[this.frames.length].length) {
          nextFrame = frames[this.frames.length];
        } else {
          this.frames.push(void 0);
        }
      }
      if (nextFrame) {
        closestFaces = this.findClosestFaceIn(nextFrame);
      }
      bestMatch = this.returnBestMatch(closestFaces);
      console.log("bestMatch is", bestMatch);
      if (bestMatch) {
        this.frames.push(bestMatch);
      } else {
        this.frames.push(void 0);
      }
      if (this.frames.length < frames.length) {
        return this.findRelatives(frames);
      } else {
        return this;
      }
    };

    Face.prototype.returnBestMatch = function(faces) {
      var face, i, match, testFace;
      match = false;
      if ((faces != null) && faces.length > 0) {
        face = this.getLatestFace();
        i = 0;
        while (!(match || i > faces.length)) {
          if (faces[i] != null) {
            testFace = faces[i];
            if (Math.abs(1 - face.width / testFace.width) < 0.6 && this.distance(face, testFace) < face.width * 0.6) {
              faces.splice(i, 1);
              match = testFace;
            }
          }
          i++;
        }
      }
      return match;
    };

    Face.prototype.getLatestFace = function() {
      var face, i;
      i = 1;
      face = false;
      while (!(face || i > this.frames.length)) {
        face = this.frames[this.frames.length - i];
        i++;
      }
      return face;
    };

    Face.prototype.fillInEyesAndMouth = function() {
      var frame, _i, _len, _ref;
      _ref = this.frames;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        frame.eyebar = {
          x: Math.round(frame.x + frame.width / 10),
          width: Math.round(frame.width / 10 * 8),
          y: Math.round(frame.y + frame.height / 3.7),
          height: Math.round(frame.height / 4)
        };
        frame.mouth = {
          x: Math.round(frame.x + frame.width / 4),
          width: Math.round(frame.width / 2),
          y: Math.round(frame.y + (frame.height / 5 * 3.1)),
          height: Math.round(frame.height / 2)
        };
        frame.mouth.center = {
          x: Math.round(frame.mouth.x + frame.mouth.width / 2),
          y: Math.round(frame.mouth.y + frame.mouth.height / 2)
        };
      }
      return this.frames;
    };

    Face.prototype.findClosestFaceIn = function(frame) {
      var face, sorted;
      face = this.getLatestFace();
      sorted = frame.sort((function(_this) {
        return function(a, b) {
          return _this.distance(a, face) - _this.distance(b, face);
        };
      })(this));
      return sorted;
    };

    Face.prototype.distance = function(obj1, obj2) {
      return Math.sqrt(Math.pow(obj1.x - obj2.x, 2) + Math.pow(obj1.y - obj2.y, 2));
    };

    Face.prototype.pulse = function(ctx, index, amount, type) {
      var maxWidth, minWidth, mouth, pulseAmount;
      mouth = this.frames[index].mouth;
      ctx.fillStyle = 'rgba(255, 255, 255, 1.0)';
      ctx.beginPath();
      minWidth = mouth.width / 3.5;
      maxWidth = mouth.width / 2;
      if (amount < 0.3) {
        pulseAmount = 0;
      } else {
        amount = (amount - 0.3) / (1.0 - 0.3);
        pulseAmount = minWidth + maxWidth * amount;
      }
      pulseAmount = Math.min(maxWidth * 0.9, pulseAmount);
      ctx.arc(mouth.center.x, mouth.center.y, pulseAmount, 0, 2 * Math.PI, false);
      ctx.globalCompositeOperation = 'source-over';
      if (type === 1) {
        ctx.fillStyle = 'white';
      } else if (type === 4) {
        ctx.fillStyle = 'black';
      } else if (type === 2) {
        ctx.fillStyle = 'black';
      } else {
        ctx.globalCompositeOperation = 'destination-out';
        ctx.fillStyle = 'black';
      }
      ctx.fill();
      return ctx.globalCompositeOperation = 'source-over';
    };

    Face.prototype.drawFace = function(ctx, index, type) {
      var face, mouthQuarterX, mouthQuarterY;
      face = this.frames[index];
      if (type === 1) {
        ctx.fillStyle = 'black';
        ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
        ctx.fillStyle = 'white';
      } else if (type === 4) {
        ctx.fillStyle = 'black';
      } else if (type === 2) {
        ctx.fillStyle = 'black';
      } else if (type === 3) {
        ctx.globalCompositeOperation = 'destination-out';
        ctx.fillStyle = 'black';
      }
      ctx.fillRect(face.eyebar.x, face.eyebar.y, face.eyebar.width, face.eyebar.height);
      mouthQuarterX = face.mouth.width / 4;
      mouthQuarterY = face.mouth.height / 4;
      ctx.beginPath();
      ctx.moveTo(face.mouth.x, face.mouth.y + mouthQuarterY);
      ctx.lineTo(face.mouth.x + mouthQuarterX * 3, face.mouth.y + face.mouth.height);
      ctx.lineTo(face.mouth.x + face.mouth.width, face.mouth.y + mouthQuarterY * 3);
      ctx.lineTo(face.mouth.x + mouthQuarterX, face.mouth.y);
      ctx.fill();
      ctx.moveTo(face.mouth.x + mouthQuarterX * 3, face.mouth.y);
      ctx.lineTo(face.mouth.x, face.mouth.y + mouthQuarterY * 3);
      ctx.lineTo(face.mouth.x + mouthQuarterX, face.mouth.y + face.mouth.height);
      ctx.lineTo(face.mouth.x + face.mouth.width, face.mouth.y + mouthQuarterY);
      ctx.fill();
      return ctx.globalCompositeOperation = 'source-over';
    };

    Face.prototype.isBegun = function() {
      var frame, _i, _len, _ref;
      if (this.started != null) {
        return this.started;
      }
      if (this.frames.length > 0) {
        _ref = this.frames;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          frame = _ref[_i];
          if ((frame != null) && frame) {
            this.started = true;
            return this.started;
          }
        }
        console.log('false');
        return false;
      } else {
        return false;
      }
    };

    return Face;

  })();

  $(function() {
    var duration;
    duration = 2;
    window.camSequence = new Sequence({
      type: 'sequence',
      src: 'webcam',
      aspect: 16 / 9,
      duration: duration,
      onStart: function() {
        return this.recordCam(duration);
      }
    });
    camSequence.drawAnimation = function(context, elapsed) {
      return $('body').append('<div class="cover"></div>');
    };
    camSequence.ended = function() {
      if (this.callback != null) {
        this.callback();
      }
      this.cleanup();
      this.video.cleanup();
      return setTimeout(function() {
        return $('.cover').remove();
      }, 500);
    };
    camSequence.recordCam = function(seconds) {
      window.recorder = this.record(this.video.canvas, seconds, false);
      return window.littleRecorder = this.record(this.video.littleCanvas, seconds, true);
    };
    camSequence.record = function(canvas, seconds, convert) {
      var complete, fps, recorder;
      recorder = new Recorder(canvas);
      if (convert) {
        complete = (function(_this) {
          return function() {
            window.converter = new Converter(recorder.canvas, recorder.capturedFrames, recorder.fps, null, {
              converted: function() {}
            });
            return converter.runWorker();
          };
        })(this);
      } else {
        complete = (function(_this) {
          return function() {
            window.allFrames = recorder.capturedFrames.slice(0);
            return _this.doProcessing(recorder.capturedFrames, recorder.fps);
          };
        })(this);
      }
      fps = 30;
      recorder.record(seconds, fps, {
        complete: complete
      });
      return recorder;
    };
    return camSequence.doProcessing = function(frames, fps) {
      frames = frames.slice(0);
      window.processor = new Processor(frames, null, fps);
      return processor.blackandwhite();
    };
  });

  CanvasPlayer = (function() {
    function CanvasPlayer(canvas, frames, fps) {
      this.canvas = canvas;
      this.frames = frames;
      this.fps = fps;
      this.paused = false;
      this.stop = false;
      this.context = this.canvas.getContext('2d');
      this.index = 0;
      this.fps = this.fps || 30;
      this.loopStyle = 'beginning';
      this.loop = false;
      this.increment = true;
      this.startFrame = 1;
      this.endFrame = this.frames.length - 1;
    }

    CanvasPlayer.prototype.reset = function() {
      this.frames = [];
      this.options = {};
      this.paused = false;
      this.index = 0;
      this.fps = this.fps || 30;
      this.loopStyle = 'beginning';
      this.increment = true;
      return this.startFrame = 0;
    };

    CanvasPlayer.prototype.setDimensions = function() {
      if (this.player != null) {
        this.canvas.width = this.player.displayWidth;
        return this.canvas.height = this.player.displayHeight;
      }
    };

    CanvasPlayer.prototype.play = function(options) {
      var frame;
      if (this.stop) {
        this.options.complete();
        return this.stop = !this.stop;
      }
      if (options.onstart != null) {
        options.onstart();
        log('start');
        options.onstart = null;
      }
      this.timeout = 1 / this.fps * 1000;
      this.options = options || this.options;
      if (this.increment && this.endFrame > this.index) {
        this.index++;
      } else if (!this.increment && this.index > 0) {
        this.index--;
      } else if ((this.options.loop != null) && this.options.loop) {
        log('decrement');
        this.increment = !this.increment;
        if (this.increment) {
          this.index++;
        } else {
          this.index--;
        }
      } else {
        return this.options.complete();
      }
      frame = this.frames[this.index];
      if (this.options.preprocess != null) {
        frame = this.options.preprocess(frame, this.index);
      }
      this.paintFrame(frame, this.index);
      if (this.options.addition != null) {
        this.options.addition(this.context, this.index);
      }
      return setTimeout((function(_this) {
        return function() {
          return _this.play(options);
        };
      })(this), this.timeout);
    };

    CanvasPlayer.prototype.timestamp = function() {
      if (window.performance && window.performance.now) {
        return window.performance.now();
      } else {
        return new Date().getTime();
      }
    };

    CanvasPlayer.prototype.pause = function() {
      return this.paused = !this.paused;
    };

    CanvasPlayer.prototype.paintFrame = function(frame, index) {
      return this.context.putImageData(frame, 0, 0);
    };

    CanvasPlayer.prototype.cleanup = function() {
      return setTimeout((function(_this) {
        return function() {
          return $(_this.canvas).remove();
        };
      })(this), 300);
    };

    return CanvasPlayer;

  })();

  Converter = (function() {
    function Converter(width, options) {
      this.width = width;
      this.options = options || {};
    }

    Converter.prototype.reset = function() {
      this.files = [];
      this.uploadedFiles = [];
      this.formdata = new FormData();
      this.fps = this.fps || 10;
      this.uploadedSprite = null;
      return this.save = false;
    };

    Converter.prototype.convertAndUpload = function() {
      var file;
      if (this.convertingFrames == null) {
        this.convertingFrames = this.frames;
      }
      if (this.convertingFrames.length > 0) {
        file = this.convertFrame(this.convertingFrames.shift());
        return this.postImage(file, {
          success: (function(_this) {
            return function(response) {
              window.faces.push(response);
              return _this.convertAndUpload();
            };
          })(this)
        });
      } else {
        log('All done converting and uploading frames');
        return alert('DONE');
      }
    };

    Converter.prototype.runWorker = function(frames, complete) {
      var frame, framesToProcess, worker, _i, _len, _results;
      this.frames = frames;
      this.complete = complete;
      worker = new Worker('/workers/findFaces.js');
      framesToProcess = (function() {
        var _i, _len, _ref, _results;
        _ref = this.frames;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i += 5) {
          frame = _ref[_i];
          _results.push(frame);
        }
        return _results;
      }).call(this);
      this.foundFaces = [];
      worker.addEventListener('message', (function(_this) {
        return function(e) {
          var bestBets;
          log("Total time took: " + (new Date().getTime() - _this.startedAt) / 1000 + 'secs');
          log('start processing images now');
          _this.foundFaces.push(e.data);
          if (_this.foundFaces.length === framesToProcess.length) {
            window.matchedFaces = new Faces(_this.foundFaces, $(document).width() / _this.width);
            bestBets = matchedFaces.groupFaces();
            return _this.complete(bestBets, matchedFaces);
          }
        };
      })(this), false);
      this.startedAt = new Date().getTime();
      _results = [];
      for (_i = 0, _len = framesToProcess.length; _i < _len; _i++) {
        frame = framesToProcess[_i];
        _results.push(worker.postMessage([frame]));
      }
      return _results;
    };

    Converter.prototype.convert = function() {
      var frame, _i, _len, _ref;
      this.files = [];
      _ref = this.frames;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        this.files.push(this.convertFrame(frame));
      }
      if (this.options.converted != null) {
        return this.options.converted();
      }
    };

    Converter.prototype.toDataURL = function(frame) {
      var dataURL;
      this.convertContext.putImageData(frame, 0, 0);
      return dataURL = this.convertCanvas.toDataURL();
    };

    Converter.prototype.convertFrame = function(frame) {
      var dataURL;
      dataURL = this.toDataURL(frame);
      return this.convertDataURL(dataURL);
    };

    Converter.prototype.convertDataURL = function(dataURL, type) {
      var array, bb, blobBin, e, file, i;
      type = type || "image/png";
      blobBin = atob(dataURL.split(',')[1]);
      array = [];
      i = 0;
      while (i < blobBin.length) {
        array.push(blobBin.charCodeAt(i));
        i++;
      }
      try {
        return file = new Blob([new Uint8Array(array)], {
          type: type
        });
      } catch (_error) {
        e = _error;
        window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder || window.MSBlobBuilder;
        if (e.name === 'TypeError' && window.BlobBuilder) {
          bb = new BlobBuilder();
          bb.append([array.buffer]);
          file = bb.getBlob("image/png");
        } else if (e.name === "InvalidStateError") {
          file = new Blob([array.buffer], {
            type: "image/png"
          });
        }
        return file;
      }
    };

    Converter.prototype.totalFileSize = function() {
      return this.files.reduce(function(acc, file) {
        return acc += file.size;
      }, 0);
    };

    Converter.prototype.framesInFinalGif = function(loopStyle) {
      if (loopStyle === 'ping-pong') {
        return (this.frames.length * 2) - 2;
      } else {
        return this.frames.length;
      }
    };

    Converter.prototype.postImage = function(file, options) {
      var formdata;
      options = options || {};
      formdata = new FormData();
      formdata.append("upload", file);
      return $.ajax({
        url: "http://localhost:3000/",
        type: "POST",
        data: formdata,
        processData: false,
        contentType: false,
        xhrFields: {
          withCredentials: false
        },
        xhr: function() {
          var req;
          req = $.ajaxSettings.xhr();
          if (req) {
            if (options.progress) {
              req.upload.addEventListener('progress', function(event) {
                if (event.lengthComputable) {
                  return options.progress(event);
                }
              }, false);
            }
          }
          return req;
        }
      }).done((function(_this) {
        return function(response) {
          if (options.success) {
            return options.success(response);
          }
        };
      })(this)).always(function() {
        if (options.complete) {
          return options.complete();
        }
      }).fail(function() {
        if (options.error) {
          return options.error();
        }
      });
    };

    Converter.prototype.postPNGs = function(options) {
      var file, index, _i, _len, _ref;
      _ref = this.files;
      for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
        file = _ref[index];
        this.formdata.append("upload[" + index + "]", file);
      }
      return $.ajax({
        url: "http://localhost:3000/",
        type: "POST",
        data: this.formdata,
        processData: false,
        contentType: 'text/plain',
        xhrFields: {
          withCredentials: false
        },
        xhr: function() {
          var req;
          req = $.ajaxSettings.xhr();
          if (req) {
            if (options && options.progress) {
              req.upload.addEventListener('progress', function(event) {
                if (event.lengthComputable) {
                  return options.progress(event);
                }
              }, false);
            }
          }
          return req;
        }
      }).done((function(_this) {
        return function(response) {
          if (options && options.success) {
            return options.success(response);
          }
        };
      })(this)).always(function() {
        log(new Date().getTime() / 1000);
        if (options && options.complete) {
          return options.complete();
        }
      }).fail(function() {
        if (options && options.error) {
          return options.error();
        }
      });
    };

    Converter.prototype.upload = function(loopStyle, options) {
      var file, i, _i, _len, _ref;
      loopStyle = loopStyle || false;
      _ref = this.files;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        file = _ref[i];
        this.appendToForm(i, file);
      }
      this.formdata.append("ping", loopStyle === 'ping-pong');
      this.formdata.append("fps", this.fps);
      this.formdata.append("authenticity_token", AUTH_TOKEN);
      if (options && options.description) {
        this.formdata.append("description", options.description);
      }
      return $.ajax({
        url: "/gifs",
        type: "POST",
        data: this.formdata,
        processData: false,
        contentType: false,
        xhr: function() {
          var req;
          req = $.ajaxSettings.xhr();
          if (req) {
            if (options && options.progress) {
              req.upload.addEventListener('progress', function(event) {
                if (event.lengthComputable) {
                  return options.progress(event);
                }
              }, false);
            }
          }
          return req;
        }
      }).done(function(response) {
        if (options && options.success) {
          return options.success(response);
        }
      }).always(function() {
        if (options && options.complete) {
          return options.complete();
        }
      }).fail(function() {
        if (options && options.error) {
          return options.error();
        }
      });
    };

    Converter.prototype.uploadToS3 = function(fileBlobs, options) {
      var $uploadForm, fd, file, index, key, postURL, _i, _len, _results;
      fileBlobs = fileBlobs || this.files;
      $uploadForm = $('#png-uploader');
      _results = [];
      for (index = _i = 0, _len = fileBlobs.length; _i < _len; index = ++_i) {
        file = fileBlobs[index];
        key = $uploadForm.data("key").replace('{index}', index).replace('{timestamp}', new Date().getTime()).replace('{unique_id}', Math.random().toString(36).substr(2, 16)).replace('{extension}', 'png');
        fd = new FormData();
        fd.append('utf8', '✓');
        fd.append('key', key);
        fd.append('acl', $uploadForm.find('#acl').val());
        fd.append('AWSAccessKeyId', $uploadForm.find('#AWSAccessKeyId').val());
        fd.append('policy', $uploadForm.find('#policy').val());
        fd.append('signature', $uploadForm.find('#signature').val());
        fd.append('success_action_status', "201");
        fd.append('X-Requested-With', "xhr");
        fd.append('Content-Type', "image/png");
        fd.append("file", file);
        postURL = $uploadForm.attr('action');
        _results.push($.ajax({
          url: postURL,
          type: "POST",
          data: fd,
          processData: false,
          contentType: false
        }).done((function(_this) {
          return function(response) {
            var pngURL;
            pngURL = $(response).find('Location').text();
            _this.uploadedFiles.push(pngURL);
            if (options && options.success) {
              return options.success(response);
            }
          };
        })(this)).always(function() {
          if (options && options.complete) {
            return options.complete();
          }
        }).fail(function() {
          if (options && options.error) {
            return options.error();
          }
        }));
      }
      return _results;
    };

    Converter.prototype.appendToForm = function(index, file) {
      return this.formdata.append("upload[" + index + "]", file);
    };

    return Converter;

  })();

  Cropper = (function() {
    function Cropper(goalDimensions) {
      this.goalDimensions = goalDimensions;
      this.transitionCanvas = this.createCanvas(this.goalDimensions);
      this.transitionContext = this.createContext(this.transitionCanvas);
      this.goalCanvas = this.createCanvas(this.goalDimensions);
      this.goalContext = this.createContext(this.goalCanvas);
    }

    Cropper.prototype.queue = function(face, frames) {
      this.frameQueue = frames.slice(0);
      this.currentFace = face;
      return this.finishedFrames = [];
    };

    Cropper.prototype.start = function(callback) {
      this.doneCallback = callback || this.doneCallback;
      this.finishedFrames.push(this.zoomToFit(this.currentFace, this.frameQueue.shift(), false));
      if (this.frameQueue.length > 0) {
        return setTimeout((function(_this) {
          return function() {
            log(_this.frameQueue.length);
            return _this.start();
          };
        })(this), 50);
      } else {
        log('zoomed on all frames');
        return this.doneCallback(this.finishedFrames);
      }
    };

    Cropper.prototype.zoomToFit = function(face, frame, isolate) {
      var canvas, cropCoords, cropData, scaleFactor;
      cropCoords = this.convertFaceCoords(face);
      this.transitionContext.putImageData(frame, 0, 0);
      cropData = this.transitionContext.getImageData(cropCoords.x, cropCoords.y, cropCoords.width, cropCoords.height);
      scaleFactor = this.goalDimensions.width / cropCoords.width;
      canvas = this.createCanvas({
        width: cropData.width,
        height: cropData.height
      });
      this.createContext(canvas).putImageData(cropData, 0, 0);
      this.goalContext.scale(scaleFactor, scaleFactor);
      this.goalContext.drawImage(canvas, 0, 0);
      this.goalContext.scale(1 / scaleFactor, 1 / scaleFactor);
      frame = this.goalContext.getImageData(0, 0, this.goalCanvas.width, this.goalCanvas.height);
      return frame;
    };

    Cropper.prototype.isolateFace = function(face, frame) {
      var center;
      log('isolate face');
      center = {
        x: frame.width / 2,
        y: frame.height / 2
      };
      face = {
        x: Math.round(center.x - frame.width / 8),
        y: Math.round(center.y - frame.width / 14),
        width: Math.round(frame.width / 5),
        height: Math.round(frame.width / 3.4)
      };
      this.goalContext.globalCompositeOperation = 'destination-in';
      this.drawEllipseByCenter(this.goalContext, center.x, center.y, face.width, face.height);
      this.goalContext.fill();
      frame = this.goalContext.getImageData(0, 0, this.goalCanvas.width, this.goalCanvas.height);
      return process.cbrFilter(frame);
    };

    Cropper.prototype.drawEllipseByCenter = function(ctx, cx, cy, w, h) {
      return this.drawEllipse(ctx, cx - w / 2.0, cy - h / 2.0, w, h);
    };

    Cropper.prototype.drawEllipse = function(ctx, x, y, w, h) {
      var kappa, ox, oy, xe, xm, ye, ym;
      kappa = .5522848;
      ox = (w / 2) * kappa;
      oy = (h / 2) * kappa;
      xe = x + w;
      ye = y + h;
      xm = x + w / 2;
      ym = y + h / 2;
      ctx.beginPath();
      ctx.moveTo(x, ym);
      ctx.bezierCurveTo(x, ym - oy, xm - ox, y, xm, y);
      ctx.bezierCurveTo(xm + ox, y, xe, ym - oy, xe, ym);
      ctx.bezierCurveTo(xe, ym + oy, xm + ox, ye, xm, ye);
      ctx.bezierCurveTo(xm - ox, ye, x, ym + oy, x, ym);
      ctx.closePath();
      return ctx.stroke();
    };

    Cropper.prototype.makeTransparent = function(frame, width) {
      var center, diagonal, distance, frameHeight, frameWidth, idata, index, midHeight, midWidth, pixel, pixelNum, targetWidth, thisPixel, y, _i, _len;
      targetWidth = 175;
      frameWidth = frame.width;
      frameHeight = frame.height;
      midHeight = frameHeight / 2;
      midWidth = frameWidth / 2;
      idata = frame.data;
      center = {
        x: frame.width / 2,
        y: frame.height / 2.2
      };
      diagonal = Math.sqrt(Math.pow(center.x, 2) + Math.pow(center.y, 2));
      for (index = _i = 0, _len = idata.length; _i < _len; index = _i += 4) {
        pixel = idata[index];
        pixelNum = index / 4;
        y = Math.floor(pixelNum / frameWidth);
        thisPixel = {
          y: y,
          x: pixelNum - y * frameWidth
        };
        distance = this.distance(thisPixel, center);
        if (distance > targetWidth) {
          idata[index + 3] = 0;
        } else {
          distance = distance * 1.3;
          if (Math.abs(midHeight - y) > targetWidth) {
            targetWidth += 40;
          }
          idata[index + 3] = 255 - (distance / targetWidth * 255);
        }
      }
      frame.data = idata;
      return frame;
    };

    Cropper.prototype.distance = function(obj1, obj2) {
      return Math.sqrt(Math.pow(obj1.x - obj2.x, 2) + Math.pow(obj1.y - obj2.y, 2));
    };

    Cropper.prototype.convertFaceCoords = function(face) {
      var center_x, center_y, height, newCoords, width;
      width = face.width * 4;
      height = width * 9 / 16;
      center_x = face.x + face.width / 2;
      center_y = face.y + face.height / 2;
      return newCoords = {
        x: Math.round(center_x - width / 2),
        y: Math.round(center_y - height / 1.9),
        width: Math.round(width),
        height: Math.round(height)
      };
    };

    Cropper.prototype.createCanvas = function(dimensions) {
      var canvas;
      canvas = document.createElement('canvas');
      canvas.width = dimensions.width;
      canvas.height = dimensions.height;
      return canvas;
    };

    Cropper.prototype.createContext = function(canvas) {
      var context;
      return context = canvas.getContext('2d');
    };

    return Cropper;

  })();

  window.debug = {
    frame: function(frame) {
      var canvas, context;
      canvas = this.createCanvas({
        width: frame.width,
        height: frame.height
      });
      $('body').html(canvas);
      context = this.createContext(canvas);
      return context.putImageData(frame, 0, 0);
    },
    createCanvas: function(dimensions) {
      var canvas;
      canvas = document.createElement('canvas');
      canvas.width = dimensions.width;
      canvas.height = dimensions.height;
      return canvas;
    },
    createContext: function(canvas) {
      var context;
      return context = canvas.getContext('2d');
    }
  };

  navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

  constraints = {
    audio: false,
    video: {
      mandatory: {
        minWidth: 1280,
        minHeight: 720
      }
    }
  };

  successCallback = function(stream) {
    window.webcam = stream;
    if (window.URL) {
      return webcam.src = window.URL.createObjectURL(stream);
    } else {
      return webcam.src = stream;
    }
  };

  errorCallback = function(error) {
    return log("navigator.getUserMedia error: ", error);
  };

  navigator.getUserMedia(constraints, successCallback, errorCallback);

  PlayController = (function() {
    function PlayController() {
      this.drawWebcam = __bind(this.drawWebcam, this);
      this.started = {
        yes: true
      };
      this.setDimensions();
      this.recordCanvas = this.createCanvas(this.displayWidth);
      this.recordCtx = this.createContext(this.recordCanvas);
      this.activeFaces = [];
      this.smallRecord = this.createCanvas(720);
      this.smallCtx = this.createContext(this.smallRecord);
      this.recorder = new Recorder(this.recordCanvas);
      this.smallRecorder = new Recorder(this.smallRecord);
      this.video = $('#mainPlayer')[0];
      this.canvas = $('#mainCanvas')[0];
      this.canvas.width = this.recordCanvas.width;
      this.canvas.height = this.recordCanvas.height;
      this.ctx = this.canvas.getContext('2d');
    }

    PlayController.prototype.init = function() {
      return $(window).on('click', (function(_this) {
        return function() {
          $('h1').remove();
          return _this.startPlayer();
        };
      })(this));
    };

    PlayController.prototype.startPlayer = function() {
      this.video.play();
      this.webcam = $('#webcam')[0];
      this.webcam.src = webcam.src;
      this.drawWebcam();
      return this.video.addEventListener('timeupdate', (function(_this) {
        return function(e) {
          return _this.checkTime(e);
        };
      })(this));
    };

    PlayController.prototype.replay = function() {
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.started = {
        yes: true
      };
      this.video.currentTime = 0;
      return this.video.play();
    };

    PlayController.prototype.drawWebcam = function() {
      this.recordCtx.drawImage(this.webcam, 0, 0, this.recordCanvas.width, this.recordCanvas.height);
      this.smallCtx.drawImage(this.webcam, 0, 0, this.smallRecord.width, this.smallRecord.height);
      if (this.recordingComplete) {
        return webcam.stop();
      } else {
        return requestAnimationFrame((function(_this) {
          return function() {
            return _this.drawWebcam();
          };
        })(this));
      }
    };

    PlayController.prototype.checkTime = function(e) {
      var time;
      time = Math.floor(this.video.currentTime);
      if (time === 2) {
        this.recordWebcam();
      }
      if (time === 12) {
        if (this.started.xFrames == null) {
          this.playback('xFrames');
        }
      }
      if (time === 28) {
        log('stop player');
        this.smoker.stopIn = 20;
      }
      if (time === 32) {
        if (this.started.firstFace == null) {
          this.playback('firstFace');
        }
      }
      if (time === 37) {
        if (this.started.secondFace == null) {
          this.playback('secondFace');
        }
      }
      if (time === 46) {
        if (this.started.xFrames2 == null) {
          this.playback('xFrames2');
        }
      }
      if (time === 52) {
        log('stop player');
        this.cPlayer.stop = true;
      }
      if (time === 54) {
        if (this.started.xFrames3 == null) {
          this.playback('xFrames3');
        }
      }
      if (time === 59) {
        log('stop player');
        this.cPlayer.stop = true;
      }
      if (time === 61) {
        return this.ctx.putImageData(this.smoker.xFrames3[9], 0, 0);
      }
    };

    PlayController.prototype.gameTime = function(e) {
      var time;
      time = Math.floor(this.video.currentTime);
      if (time === 127) {
        this.recordWebcam();
      }
      if (time === 142) {
        if (this.started.firstFace == null) {
          this.playback('firstFace');
        }
      }
      if (time === 149) {
        if (this.started.secondFace == null) {
          this.playback('secondFace');
        }
      }
      if (time === 155) {
        if (this.started.xFrames == null) {
          this.playback('xFrames');
        }
      }
      if (time === 168) {
        log('stop player 1');
        this.smoker.stopIn = 20;
      }
      if (time === 174) {
        if (this.started.xFrames2 == null) {
          this.playback('xFrames2');
        }
      }
      if (time === 187) {
        this.cPlayer.stop = true;
      }
      if (time === 192) {
        if (this.started.xFrames3 == null) {
          this.playback('xFrames3');
        }
      }
      if (time === 197) {
        log('stop player');
        this.cPlayer.stop = true;
      }
      if (time === 200) {
        return this.ctx.putImageData(this.smoker.xFrames3[9], 0, 0);
      }
    };

    PlayController.prototype.playback = function(segment) {
      log('play ' + segment);
      this.started[segment] = true;
      segment = this.smoker.segments[segment];
      log('playing');
      if (segment != null) {
        this.cPlayer = new CanvasPlayer(this.canvas, segment.frames, 15);
        return this.cPlayer.play({
          loop: segment.loop,
          preprocess: segment.preprocess,
          postprocess: segment.postprocess,
          onstart: segment.start,
          addition: segment.addition,
          complete: (function(_this) {
            return function() {
              _this.ctx.clearRect(0, 0, _this.canvas.width, _this.canvas.height);
              log('done playing');
              if (segment.complete != null) {
                return segment.complete();
              }
            };
          })(this)
        });
      } else {
        return log('segment was not finished');
      }
    };

    PlayController.prototype.recordWebcam = function() {
      var secs;
      if (this.smoker != null) {
        return;
      }
      secs = 2;
      if (!this.recorder.started) {
        log('start recording');
        this.smoker = new Smoker(this.recordCanvas, this.recordCtx, this);
        this.recorder.record(secs, 30, {
          complete: (function(_this) {
            return function() {
              log('done recording');
              _this.smoker.setFrames(_this.recorder.capturedFrames.slice(0), _this.recorder.fps);
              _this.startProcessing(_this.recorder.capturedFrames, _this.recorder.fps);
              return _this.recordingComplete = true;
            };
          })(this)
        });
      }
      if (!this.smallRecorder.started) {
        return this.smallRecorder.record(secs, 30, {
          complete: (function(_this) {
            return function() {
              _this.smoker.setSmall(_this.smallRecorder.capturedFrames);
              _this.smoker.findFaces();
              _this.recordingComplete = true;
              log('now find faces');
              return _this.smallRecorder = null;
            };
          })(this)
        });
      }
    };

    PlayController.prototype.startProcessing = function(frames, fps) {
      var faces, processor;
      frames = frames.slice(0);
      this.recorder.capturedFrames = null;
      processor = new Processor(frames, null, fps);
      return faces = processor.bnwFrames = processor.blackandwhite({
        complete: (function(_this) {
          return function(bnwFrames) {
            _this.smoker.setBNW(bnwFrames);
            return bnwFrames = null;
          };
        })(this)
      });
    };

    PlayController.prototype.findFaces = function() {
      var converter;
      converter = new Converter(this.recorder.canvas, this.recorder.capturedFrames, this.recorder.fps, null, {
        converted: function() {}
      });
      return converter.runWorker();
    };

    PlayController.prototype.setDimensions = function(canvas) {
      this.displayWidth = $(document).width();
      return this.displayHeight = $(document).height();
    };

    PlayController.prototype.createCanvas = function(width) {
      var canvas;
      canvas = document.createElement('canvas');
      canvas.height = Math.ceil(width * 9 / 16);
      canvas.width = width;
      return canvas;
    };

    PlayController.prototype.createContext = function(canvas) {
      var context;
      return context = canvas.getContext('2d');
    };

    return PlayController;

  })();

  $(function() {
    window.playbackCamSequence = new Sequence({
      type: 'sequence',
      aspect: 16 / 9,
      duration: 3,
      src: 'CanvasPlayer'
    });
    return playbackCamSequence.ended = function() {
      if (this.callback != null) {
        this.callback();
      }
      this.cleanup();
      return this.video.cleanup();
    };
  });

  window.process = {
    cbrFilter: function(frame) {
      var alpha, b, cB, cR, g, idata, index, pixel, r, y, _i, _len;
      idata = frame.data;
      for (index = _i = 0, _len = idata.length; _i < _len; index = _i += 4) {
        pixel = idata[index];
        r = idata[index];
        g = idata[index + 1];
        b = idata[index + 2];
        y = 0.299 * r + 0.587 * g + 0.114 * b;
        cB = 128 + (-0.169 * r + 0.331 * g + 0.5 * b);
        cR = 128 + (0.5 * r - 0.419 * g - 0.081 * b);
        if (cR > 80 && cR > 127 && cB > 137 && cB < 165 && y > 26 && y < 226) {
          idata[index] = 255;
          idata[index + 1] = 255;
          idata[index + 2] = 255;
          if (typeof audioIntensity !== "undefined" && audioIntensity !== null) {
            alpha = ((255 - audioIntensity * 255) + 100) / 200;
          } else {
            window.audioIntensity = 0;
          }
          idata[index + 3] = alpha;
        } else {
          idata[index + 3] = 0;
        }
      }
      frame.data = idata;
      return frame;
    }
  };

  Processor = (function() {
    function Processor(frames, faces, options) {
      this.frames = frames;
      this.faces = faces;
      this.options = options;
      this.newFrames = [];
      this.playFrames = [];
    }

    Processor.prototype.zoomOnFace = function(face) {
      var centerFace, crop;
      if ((face.frames == null) || face.frames.length < 7) {
        return;
      }
      centerFace = face.frames[6];
      crop = new Cropper({
        width: player.displayWidth,
        height: player.displayHeight
      });
      crop.queue(centerFace, allFrames);
      return crop.start((function(_this) {
        return function(frames) {
          console.log('done running cropper');
          return _this.addSequence(frames, true);
        };
      })(this));
    };

    Processor.prototype.blackandwhite = function(options) {
      var newFrames, worker;
      options = options || {};
      newFrames = [];
      worker = new Worker('/workers/bnw.js');
      worker.addEventListener('message', (function(_this) {
        return function(e) {
          newFrames.push(e.data[0]);
          if (newFrames.length === _this.frames.length) {
            log('time to add sequence to player');
            log("Total time took: " + (new Date().getTime() - _this.startedAt) / 1000 + 'secs');
            _this.playFrames = newFrames;
            return options.complete(newFrames);
          } else {
            return worker.postMessage([_this.frames[newFrames.length]]);
          }
        };
      })(this), false);
      this.startedAt = new Date().getTime();
      return worker.postMessage([this.frames[0]]);
    };

    Processor.prototype.drawFaceRects = function(faces, scale) {
      var newFrames;
      this.faces = faces;
      this.scale = scale;
      newFrames = [];
      this.worker = new Worker('/workers/drawFaceRect.js');
      this.worker.addEventListener('message', (function(_this) {
        return function(e) {
          newFrames.push(e.data[0]);
          if (newFrames.length === _this.frames.length) {
            log('time to add sequence to player');
            log("Total time took: " + (new Date().getTime() - _this.startedAt) / 1000 + 'secs');
            return _this.addSequence(newFrames);
          } else {
            return _this.sendFrame(newFrames.length, scale);
          }
        };
      })(this), false);
      this.startedAt = new Date().getTime();
      this.newFaces = this.faces;
      return this.sendFrame(0, scale);
    };

    Processor.prototype.sendFrame = function(index, scale) {
      var frame, params;
      frame = this.frames[index];
      if (frame == null) {
        debugger;
      }
      if (frame != null) {
        params = {
          frames: [frame],
          frameNumber: index,
          faces: this.newFaces[index],
          scale: scale || 3,
          spacer: Math.round(window.spacer)
        };
        return this.worker.postMessage(params);
      } else {
        console.log('shit wtf no frame?');
        if (!(index <= this.frames.length)) {
          return this.sendFrame(index + 1);
        }
      }
    };

    Processor.prototype.queueEyebarSequence = function(faces) {
      var sequence;
      sequence = new Sequence({
        type: 'sequence',
        aspect: 16 / 9,
        duration: 3,
        src: 'CanvasPlayer',
        frames: window.allFrames,
        faces: faces,
        name: 'Eyebar'
      });
      sequence.ended = function() {
        if (this.callback != null) {
          this.callback();
        }
        this.cleanup();
        return this.video.cleanup();
      };
      sequence.drawAnimation = function(index) {
        var face, mouthQuarterX, mouthQuarterY, thisFace, _i, _len, _ref, _results;
        _ref = this.options.faces;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          thisFace = _ref[_i];
          face = thisFace.frames[index];
          this.context.fillStyle = 'rgba(0, 0, 0, 1.0)';
          this.context.fillOpacity = 0.1;
          this.context.fillRect(face.eyebar.x, face.eyebar.y, face.eyebar.width, face.eyebar.height);
          mouthQuarterX = face.mouth.width / 4;
          mouthQuarterY = face.mouth.height / 4;
          this.context.beginPath();
          this.context.moveTo(face.mouth.x, face.mouth.y + mouthQuarterY);
          this.context.lineTo(face.mouth.x + mouthQuarterX * 3, face.mouth.y + face.mouth.height);
          this.context.lineTo(face.mouth.x + face.mouth.width, face.mouth.y + mouthQuarterY * 3);
          this.context.lineTo(face.mouth.x + mouthQuarterX, face.mouth.y);
          this.context.fill();
          this.context.moveTo(face.mouth.x + mouthQuarterX * 3, face.mouth.y);
          this.context.lineTo(face.mouth.x, face.mouth.y + mouthQuarterY * 3);
          this.context.lineTo(face.mouth.x + mouthQuarterX, face.mouth.y + face.mouth.height);
          this.context.lineTo(face.mouth.x + face.mouth.width, face.mouth.y + mouthQuarterY);
          _results.push(this.context.fill());
        }
        return _results;
      };
      return player.addTrack(sequence);
    };

    Processor.prototype.saturate = function(percent) {
      var frame, newFrames, worker, _i, _len, _ref, _results;
      newFrames = [];
      worker = new Worker('/workers/saturate.js');
      worker.addEventListener('message', (function(_this) {
        return function(e) {
          newFrames.push(e.data[0]);
          if (newFrames.length === _this.frames.length) {
            log('time to add sequence to player');
            log("Total time took: " + (new Date().getTime() - _this.startedAt) / 1000 + 'secs');
            _this.playFrames = newFrames;
            return _this.addSequence();
          }
        };
      })(this), false);
      this.startedAt = new Date().getTime();
      _ref = this.frames;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        _results.push(worker.postMessage([frame]));
      }
      return _results;
    };

    Processor.prototype.blur = function(rate) {
      var frame, newFrames, worker, _i, _len, _ref, _results;
      newFrames = [];
      worker = new Worker('/workers/blur.js');
      worker.addEventListener('message', (function(_this) {
        return function(e) {
          newFrames.push(e.data[0]);
          if (newFrames.length === _this.frames.length) {
            log('time to add sequence to player');
            log("Total time took: " + (new Date().getTime() - _this.startedAt) / 1000 + 'secs');
            _this.playFrames = newFrames;
            return _this.addSequence();
          }
        };
      })(this), false);
      this.startedAt = new Date().getTime();
      _ref = this.frames;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        frame = _ref[_i];
        _results.push(worker.postMessage([frame]));
      }
      return _results;
    };

    Processor.prototype.addSequence = function(frames, addSpacer) {
      var sequence;
      frames = frames || this.playFrames;
      addSpacer = addSpacer || false;
      sequence = new Sequence({
        type: 'sequence',
        aspect: 16 / 9,
        duration: 3,
        src: 'CanvasPlayer',
        frames: frames,
        addSpacer: addSpacer
      });
      sequence.ended = function() {
        if (this.callback != null) {
          this.callback();
        }
        this.cleanup();
        return this.video.cleanup();
      };
      player.addTrack(sequence);
      return log('added track');
    };

    return Processor;

  })();

  Recorder = (function() {
    function Recorder(canvas) {
      this.canvas = canvas;
      this.captureFrames = __bind(this.captureFrames, this);
      this.capturedFrames = [];
      this.context = this.canvas.getContext('2d');
      this.width = this.canvas.width;
      this.height = this.canvas.height;
      this.started = false;
    }

    Recorder.prototype.reset = function() {
      return this.capturedFrames = [];
    };

    Recorder.prototype.record = function(seconds, fps, options) {
      var frames;
      this.fps = fps;
      this.options = options;
      this.started = true;
      this.options = this.options || {};
      this.fps = this.fps || 30;
      seconds = seconds || 3;
      this.totalFrames = seconds * this.fps;
      frames = this.totalFrames;
      return this.captureFrames(frames);
    };

    Recorder.prototype.captureFrames = function(frames) {
      this.options = this.options || {};
      if (frames > 0) {
        this.capturedFrames.push(this.context.getImageData(0, 0, this.width, this.height));
        frames--;
        setTimeout((function(_this) {
          return function() {
            return _this.captureFrames(frames);
          };
        })(this), 1000 / this.fps);
        if (this.options.progress) {
          return this.options.progress((this.totalFrames - frames) / this.totalFrames, this.capturedFrames[this.capturedFrames.length - 1]);
        }
      } else {
        if (this.options.complete) {
          return this.options.complete();
        }
      }
    };

    return Recorder;

  })();

  Smoker = (function() {
    function Smoker(canvas, context, player) {
      this.canvas = canvas;
      this.context = context;
      this.player = player;
      this.drawAlphaFace = __bind(this.drawAlphaFace, this);
      this.pulseMouths = __bind(this.pulseMouths, this);
      this.pulseBlack = __bind(this.pulseBlack, this);
      this.frames = [];
      this.smallFrames = [];
      this.bnwFrames = [];
      this.segments = {};
      this.xFrames = [];
      this.xFrames2 = [];
      this.xFrames3 = [];
    }

    Smoker.prototype.setBNW = function(frames) {
      this.bnwFrames = frames.slice(0);
      this.segments.xFrames = {
        frames: this.bnwFrames,
        loop: true,
        addition: (function(_this) {
          return function(ctx, index) {
            return _this.pulseMouths(ctx, index, 1);
          };
        })(this),
        start: (function(_this) {
          return function() {
            return new soundAnalyzer(_this.player).playSound();
          };
        })(this)
      };
      if (this.faces != null) {
        return this.setupZooms();
      }
    };

    Smoker.prototype.setFrames = function(frames, fps) {
      this.frames = frames.slice(0);
      this.width = this.frames[0].width;
      this.height = this.frames[0].height;
      this.segments.raw = {
        frames: this.frames
      };
      return this.fps = fps;
    };

    Smoker.prototype.setSmall = function(frames) {
      return this.smallFrames = frames.slice(0);
    };

    Smoker.prototype.findFaces = function() {
      var converter;
      converter = new Converter(this.smallFrames[0].width);
      return converter.runWorker(this.smallFrames, (function(_this) {
        return function(faces, faceCollection) {
          _this.faceCollection = faceCollection;
          _this.faces = _this.faceCollection.sortByCertainty(faces);
          _this.faceCollection.applyScale(_this.frames[0].width / _this.smallFrames[0].width);
          _this.faceCollection.fillInBlanks(3);
          _this.smallFrames = [];
          _this.frames = [];
          converter = null;
          _this.player.recorder = null;
          _this.player.smallRecorder = null;
          log('got all the faces', _this.faces);
          if (_this.bnwFrames.length > 0) {
            return _this.setupZooms();
          }
        };
      })(this));
    };

    Smoker.prototype.processXFrames = function(inProcess, index, type) {
      var frame;
      inProcess = inProcess || this.bnwFrames.slice(0);
      index = index || 0;
      frame = inProcess.shift();
      this.context.putImageData(frame, 0, 0);
      this.drawFaces(this.context, index, type);
      if (type === 1) {
        this.xFrames.push(this.context.getImageData(0, 0, this.canvas.width, this.canvas.height));
      } else if (type === 2) {
        this.xFrames2.push(this.context.getImageData(0, 0, this.canvas.width, this.canvas.height));
      } else {
        this.xFrames3.push(this.context.getImageData(0, 0, this.canvas.width, this.canvas.height));
      }
      if (inProcess.length > 0) {
        return setTimeout((function(_this) {
          return function() {
            log(index);
            index++;
            return _this.processXFrames(inProcess, index, type);
          };
        })(this), 50);
      } else {
        log('done with processXFrames ' + type);
        if (type === 2) {
          this.segments.xFrames2 = {
            frames: this.xFrames2,
            loop: true,
            addition: (function(_this) {
              return function(ctx, index) {
                return _this.pulseMouths(ctx, index, 2);
              };
            })(this)
          };
          return this.processXFrames(null, null, 3);
        } else {
          return this.segments.xFrames3 = {
            frames: this.xFrames3,
            loop: true,
            addition: (function(_this) {
              return function(ctx, index) {
                return _this.pulseMouths(ctx, index, 3);
              };
            })(this)
          };
        }
      }
    };

    Smoker.prototype.setupZooms = function() {
      var i, zoomFaces, _i;
      if (this.faces.length > 0) {
        zoomFaces = [];
        for (i = _i = 0; _i <= 2; i = ++_i) {
          if (i < this.faces.length) {
            zoomFaces[i] = this.faces[i];
          } else {
            zoomFaces[i] = this.faces[0];
          }
        }
        return this.zoomOnFace(zoomFaces[0], (function(_this) {
          return function(frames) {
            var index;
            log('zoom ready');
            index = 0;
            _this.segments.firstFace = {
              frames: frames,
              addition: _this.fadeInOut
            };
            return _this.getSecondFace(zoomFaces);
          };
        })(this));
      } else {
        return log('no faces to zoom on');
      }
    };

    Smoker.prototype.zoomOnFace = function(face, complete) {
      var centerFace, crop, frames;
      if ((face.frames == null) || face.frames.length < 7) {
        return;
      }
      log('zoomonface');
      frames = this.bnwFrames;
      centerFace = face.getAverageFace();
      crop = new Cropper({
        width: this.width,
        height: this.height
      });
      crop.queue(centerFace, frames);
      return crop.start((function(_this) {
        return function(frames) {
          console.log('done running cropper');
          complete(frames);
          crop = null;
          return frames = null;
        };
      })(this));
    };

    Smoker.prototype.getSecondFace = function(zoomFaces) {
      return this.zoomOnFace(zoomFaces[1], (function(_this) {
        return function(frames) {
          log('got second face');
          _this.segments.secondFace = {
            frames: frames,
            addition: _this.fadeInOut
          };
          return _this.processXFrames(null, null, 2);
        };
      })(this));
    };

    Smoker.prototype.getThirdFace = function(zoomFaces) {
      return this.zoomOnFace(zoomFaces[2], (function(_this) {
        return function(frames) {
          _this.segments.thirdFace = {
            frames: frames,
            preprocess: _this.cbrFilter
          };
          return _this.processXFrames(null, null, 1);
        };
      })(this));
    };

    Smoker.prototype.getAlphaFace = function() {
      var crop, face, frame, i, _i;
      log('get alpha face');
      face = this.faces[0].frames[8];
      frame = this.frames.slice(8, 9)[0];
      crop = new Cropper({
        width: this.width,
        height: this.height
      });
      this.alphaFace = crop.zoomToFit(face, frame, true);
      this.alphaFrames = [];
      for (i = _i = 0; _i <= 190; i = ++_i) {
        this.alphaFrames.push(this.alphaFace);
      }
      return this.segments.alphaFace = {
        frames: this.alphaFrames
      };
    };

    Smoker.prototype.drawFaces = function(ctx, index, type) {
      var face, _i, _len, _ref, _results;
      if (type === 1) {
        this.activeFaces = this.faces.slice(0, 1);
      }
      if (type === 2) {
        this.activeFaces = this.faces.slice(0, 3);
      }
      if (type === 3) {
        this.activeFaces = this.faces;
      }
      if (this.activeFaces.length > 0) {
        _ref = this.activeFaces;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          face = _ref[_i];
          _results.push(face.drawFace(ctx, index, type));
        }
        return _results;
      }
    };

    Smoker.prototype.pulseBlack = function(frame) {
      var g, idata, index, pixel, r, trans, _i, _len;
      idata = frame.data;
      trans = Math.floor((255 - audioIntensity * 255) + 100);
      for (index = _i = 0, _len = idata.length; _i < _len; index = _i += 4) {
        pixel = idata[index];
        r = idata[index];
        g = idata[index + 1];
        if (r === 5 && g === 0) {
          idata[index + 3] = 0;
        }
      }
      frame.data = idata;
      return frame;
    };

    Smoker.prototype.cbrFilter = function(frame) {
      return process.cbrFilter(frame);
    };

    Smoker.prototype.fadeInOut = function(ctx, index) {
      var alpha;
      if (index < 30) {
        alpha = 1 - index / 30;
        ctx.fillStyle = 'rgba(0, 0, 0,' + alpha + ')';
      } else if (index > 30) {
        alpha = index % 30 / 30;
        ctx.fillStyle = 'rgba(0, 0, 0,' + alpha + ')';
      }
      return ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    };

    Smoker.prototype.alphaInOut = function(frame, index) {
      var alpha, idata, pixel, _i, _len;
      if (index < 45) {
        alpha = 255 * (1 - index / 45);
      } else if (index > 45) {
        alpha = 255 * (index % 45 / 45);
      }
      log(index);
      log(alpha);
      alpha = Math.floor(alpha);
      idata = frame.data;
      for (index = _i = 0, _len = idata.length; _i < _len; index = ++_i) {
        pixel = idata[index];
        idata[index + 3] = alpha;
      }
      frame.data = idata;
      return frame;
    };

    Smoker.prototype.pulseMouths = function(ctx, index, type) {
      var face, faces, _i, _len, _results;
      this.type = type;
      if (this.faces.length > 0) {
        if (type === 1) {
          face = this.faces[0];
          faces = [face];
          if (this.stopIn != null) {
            type = 4;
            this.type = type;
            this.stopIn--;
            log('stopIn', this.stopIn);
            if (this.stopIn % 2 === 0) {
              ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
              ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
            } else {
              ctx.fillStyle = 'rgba(0, 0, 0, 0.6)';
              ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
            }
            if (this.stopIn < 1) {
              log('stop for real ' + type);
              this.stopIn = null;
              this.player.cPlayer.stop = true;
            }
          } else {
            ctx.fillStyle = 'black';
            ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
          }
          face.drawFace(ctx, index, type);
        } else if (type === 2) {
          faces = this.faces.slice(0, 3);
        } else {
          faces = this.faces;
        }
        _results = [];
        for (_i = 0, _len = faces.length; _i < _len; _i++) {
          face = faces[_i];
          _results.push(face.pulse(ctx, index, audioIntensity, type));
        }
        return _results;
      }
    };

    Smoker.prototype.drawAlphaFace = function(ctx, index) {
      var frame;
      return frame = {
        width: ctx.canvas.width,
        height: ctx.canvas.height
      };
    };

    return Smoker;

  })();

  $(function() {
    var init;
    window.video = $('video')[0];
    window.audioIntensity = 0.5;
    init = function() {
      window.player = new PlayController();
      return player.init();
    };
    init();
    return $(window).resize(function() {
      return player.setDimensions();
    });
  });

}).call(this);

//# sourceMappingURL=app.js.map
