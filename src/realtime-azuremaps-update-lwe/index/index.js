//MIT License
//
//Copyright (c) Microsoft Corporation.
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE
var fs = require('fs');
var path = require('path');

module.exports = function (context, req) {
    var index = 'index.html';
    if (process.env["HOME"] != null)
    {
        index = path.join(process.env["HOME"], "site", "wwwroot", index);
    }
    context.log("index.html path: " + index);
    fs.readFile(index, 'utf8', function (err, data) {
        if (err) {
            console.log(err);
            context.done(err);
        }
        context.res = {
            status: 200,
            headers: {
                'Content-Type': 'text/html'
            },
            body: data
        };
        context.done();
    });
}