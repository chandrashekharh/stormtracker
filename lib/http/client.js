// Generated by CoffeeScript 1.8.0
(function() {
  var HttpClient, http;

  http = require("http");

  HttpClient = (function() {
    function HttpClient(host, port) {
      this.host = host;
      this.port = port;
    }

    HttpClient.prototype.get = function(path, headers, callback) {
      if (callback == null) {
        callback = function() {};
      }
      return this.send(path, null, headers, "GET", callback);
    };

    HttpClient.prototype.post = function(path, data, headers, callback) {
      if (callback == null) {
        callback = function() {};
      }
      return this.send(path, data, headers, "POST", callback);
    };

    HttpClient.prototype.put = function(path, data, callback) {
      if (callback == null) {
        callback = function() {};
      }
      return this.send(path, data, headers, "PUT", callback);
    };

    HttpClient.prototype["delete"] = function(path, data, headers, callback) {
      if (callback == null) {
        callback = function() {};
      }
      return this.send(path, data, headers, "DELETE", callback);
    };

    HttpClient.prototype.send = function(path, data, headers, method, callback) {
      var request;
      if (callback == null) {
        callback = function() {};
      }
      headers["content-type"] = "application/json";
      request = http.request({
        host: this.host,
        port: this.port,
        path: path,
        method: method,
        headers: headers
      }, function(response) {
        var body;
        body = "";
        response.on("data", function(chunk) {
          return body += chunk;
        });
        response.on("end", function() {
          var ctype, err;
          if (response.statusCode === 200) {
            ctype = response.headers["content-type"].split(";");
            if ("application/json" === ctype[0].trim()) {
              body = JSON.parse(body);
              return callback(null, body);
            }
          } else {
            err = new Error("Not a proper response, status code=" + response.statusCode);
            err.statusCode = response.statusCode;
            return callback(err, null);
          }
        });
        return response.on("error", function(error) {
          return callback(error, null);
        });
      });
      request.on("error", function(error) {
        return callback(error, null);
      });
      if (data) {
        request.write(JSON.stringify(data));
      }
      return request.end();
    };

    return HttpClient;

  })();

  exports.HttpClient = HttpClient;

}).call(this);
