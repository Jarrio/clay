package clay.sdl;

import clay.buffers.ArrayBufferView;
import clay.buffers.Uint8Array;
import clay.native.NativeIO;
import sdl.SDL;

typedef FileHandle = sdl.RWops;

enum abstract FileSeek(Int) from Int to Int {
    var SET = 0;
    var CUR = 1;
    var END = 2;
}

class SDLIO extends NativeIO {

    override public function isSynchronous():Bool {

        return true;

    }

    override function appPath():String {

        var path = SDL.getBasePath();
        if (path == null) path = '';

        return path;

    }

    override function appPathPrefs():String {

        var parts = Clay.app.appId.split('.');
        var appName = parts.pop();
        var org = parts.join('.');

        return SDL.getPrefPath(org, appName);

    }

    override function loadData(path:String, binary:Bool = false, async:Bool = false, ?callback:(data:Uint8Array)->Void):Uint8Array {

        if (path == null)
            throw 'Path is null!';

        var dest:Uint8Array = null;
        if (async) {
            Clay.app.backgroundQueue.schedule(function() {
                dest = _doLoadData(path, binary);
                Runner.runInMain(function() {
                    if (callback != null) {
                        Immediate.push(() -> {
                            callback(dest);
                        });
                    }
                });
            });
        }
        else {
            dest = _doLoadData(path, binary);
            if (callback != null) {
                Immediate.push(() -> {
                    callback(dest);
                });
            }
        }
        return dest;

    }

    private function _doLoadData(path:String, binary:Bool):Uint8Array {

        var file = SDL.RWFromFile(path, binary ? 'rb' : 'r');

        if (file == null) {
            return null;
        }
        var size = fileSize(file);
        var dest = new Uint8Array(size);

        if (size != 0) {
            fileRead(file, dest, dest.length, 1);
        }

        // close + release the file handle
        fileClose(file);

        return dest;

    }

/// File IO

    public function fileHandle(path:String, mode:String = "rb"):FileHandle {

        return SDL.RWFromFile(path, mode);

    }

    public function fileHandleFromMem(mem:ArrayBufferView, size:Int):FileHandle {

        return SDL.RWFromMem(mem.buffer, size);

    }

    public function fileRead(file:FileHandle , dest:ArrayBufferView, size:Int, maxnum:Int):Int {

        if (file == null)
            throw 'Parameter `file` should not be null';

        return SDL.RWread(file, dest.buffer, size, maxnum);

    }

    public function fileWrite(file:FileHandle, src:ArrayBufferView, size:Int, num:Int):Int {

        if (file == null)
            throw 'Parameter `file` should not be null';

        return SDL.RWwrite(file, src.buffer, size, num);

    }

    public function fileSeek(file:FileHandle, offset:Int, whence:Int):Int {

        if (file == null)
            throw 'Parameter `file` should not be null';

        return haxe.Int64.toInt(SDL.RWseek(file, offset, whence));

    }

    public function fileTell(file:FileHandle):Int {

        if (file == null)
            throw 'Parameter `file` should not be null';

        return haxe.Int64.toInt(SDL.RWtell(file));

    }

    public function fileClose(file:FileHandle):Int {

        if (file == null)
            throw 'Parameter `file` should not be null';

        return SDL.RWclose(file);

    }

    public function fileSize(handle:FileHandle):UInt {

        var cur = fileTell(handle);
        fileSeek(handle, 0, FileSeek.END);
        var size = fileTell(handle);
        fileSeek(handle, cur, FileSeek.SET);
        return size;

    }

}
