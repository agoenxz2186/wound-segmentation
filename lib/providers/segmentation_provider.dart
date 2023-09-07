import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class SegmentationProvider with ChangeNotifier{
    File? fileImage;
    bool isProcessing = false;
    final String _modelPath = 'assets/models/tflite_mobnetv2.tflite';
    Interpreter? _interpreter;
    Tensor? t_input, t_output;
    Uint8List? memoryResult;
    InferenceIsolate? inferenceIsolate;
    bool processing = false;
    int totaltime = 0;
 
    void setFile(File f){
        fileImage = f;
        processing = false;
        notifyListeners();
    }

    void close(){
        inferenceIsolate?.close();
    }

    Future<Interpreter> loadModel()async{
        inferenceIsolate = InferenceIsolate(); 
        await inferenceIsolate!.start();

        final interpreterOptions = InterpreterOptions();
        interpreterOptions.threads = 4;
      
        if(Platform.isAndroid){
            interpreterOptions.addDelegate(XNNPackDelegate());
            interpreterOptions.useNnApiForAndroid = true;
        }

        if(Platform.isIOS){
           interpreterOptions.addDelegate(GpuDelegate());
        }
        

        _interpreter = await Interpreter.fromAsset(_modelPath, options: interpreterOptions);
        t_input = _interpreter!.getInputTensors().first;
        t_output = _interpreter!.getOutputTensors().first;
        print('load model $_modelPath sukses');
        return _interpreter!;
    }

    Future segmentation(String imagePath)async{
        if(_interpreter == null){
            print('Belum load model');
            return null;
        }
        memoryResult = null;
        processing = true;
        notifyListeners();

        final imgData = File(imagePath).readAsBytesSync();
        final image = img.decodeImage(imgData);

        ReceivePort receivePort = ReceivePort();

        InferenceModel inferenceModel = InferenceModel(
          interpreterAddress: _interpreter?.address,
          image: image,
          t_input: t_input!.shape,
          t_output: t_output!.shape,
          responsePort: receivePort.sendPort
        );
        final awal = DateTime.now(); 
        inferenceIsolate?.sendPort?.send( inferenceModel  );
 
        memoryResult = await receivePort.first;
        final akhir = DateTime.now();
        final compare = akhir.difference(awal);
        print("lama inference luar ${compare.inMilliseconds}");
        totaltime = compare.inMilliseconds;

        processing = false;
        notifyListeners();
    }

    
}

List<List<List>> squeezeList(List<List<List<List>>> inputList) {
        if (inputList.length != 1) {
          throw ArgumentError("Input List harus memiliki panjang 1");
        }

        final input = inputList[0];
        final height = input.length;
        final width = input[0].length;
        final depth = input[0][0].length;

        if (depth != 1) {
          throw ArgumentError("Input List harus memiliki kedalaman 1");
        }

        final squeezedList = List.generate(height, (i) {
          return List.generate(width, (j) {
            return [input[i][j][0]];
          });
        });

        return squeezedList;
      }


class InferenceModel{
    img.Image? image;
    int? interpreterAddress;
    List? t_input;
    List? t_output;
    SendPort? responsePort;
    
    InferenceModel({this.image, this.interpreterAddress, this.t_input, this.t_output, this.responsePort});
}

class InferenceIsolate{
    final ReceivePort _receivePort = ReceivePort();
    Isolate? _isolate;
    SendPort? _sendPort;

    SendPort? get sendPort => _sendPort;

    Future start()async{
        _isolate = await Isolate.spawn(entryPoint, _receivePort.sendPort);
        _sendPort = await _receivePort.first;
    }

    Future close()async{
      _isolate?.kill();
      _receivePort.close();
    }

    static void entryPoint(SendPort sendPort)async{
        final port = ReceivePort();
        sendPort.send(port.sendPort);

        await for(final InferenceModel isolateModel in port){
            img.Image? imgs = isolateModel.image;

              //resize to 224 x 224
            final imageInput = img.copyResize(imgs!, 
              width:   isolateModel.t_input?[1] ?? 224,
              height:  isolateModel.t_input?[2] ?? 224
            );

            //create shape [224, 224, 3]
            final imageMetrix = List.generate(imageInput.height, 
                (y) => List.generate(
                  imageInput.width,
                  (x){
                      final pixel = imageInput.getPixel(x, y);
                      final rgb = [pixel.r / 127.5, pixel.g / 127.5, pixel.b / 127.5];
                      return [rgb[0]-1.0, rgb[1] - 1.0, rgb[2] -1.0 ];
                      // return [pixel.r /255, pixel.g / 255, pixel.b / 255];
                  }
              ));

            //set input to [1, 224, 224, 3]
            final input  = [imageMetrix];

            //set output to [1,255,255,1]
            final output = [List.filled(isolateModel.t_output?[1] ?? 224,  
                          List.filled(isolateModel.t_output?[2] ?? 224,
                          List.filled(isolateModel.t_output?[3] ?? 1, 0.0)  )  )];
          
            Interpreter interpreter = Interpreter.fromAddress(isolateModel.interpreterAddress!);
            final a = DateTime.now();
            interpreter.run(input, output);
            final c = DateTime.now().difference(a);
            print('lama inferensi dalam : ${c.inMilliseconds}');

            img.Image temp = img.Image(width: 224, height: 224);
             
            final result = squeezeList(output); 

            final a1 = DateTime.now();

            for(var y = 0; y<result.shape[0]; y++){
                for(var x=0; x<result.shape[1]; x++){
                  img.Color c = imageInput.getPixel(x, y);  
                  final confidence = result[y][x][0]  ;
                  if( confidence < 0.01){ 
                    c = img.ColorRgb8(255, 255, 255); 
                  }
                  temp.setPixel(x, y, c);
                }
            }

            final b1 = DateTime.now().difference(a1);
            print('lama susun pixel : ${b1.inMilliseconds}');

            final memoryResult = img.encodePng(temp);
            isolateModel.responsePort?.send(memoryResult);

        }
    }
}