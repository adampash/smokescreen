var uploader;

importScripts('/workers/formdata.js');

importScripts('/assets/js/jquery.hive.pollen.js');

uploader = {
  post: function(file, callback) {
    var formdata, options, req;
    options = options || {};
    formdata = new FormData();
    formdata.append("upload", file);
    req = new XMLHttpRequest();
    req.onload = function() {
      return callback(this.responseText);
    };
    req.open("post", "http://localhost:3000/", true);
    return req.send(formdata);
  }
};

//# sourceMappingURL=uploader.js.map
