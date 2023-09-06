import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:segmentation/providers/segmentation_provider.dart';
import 'package:segmentation/utilities/assets.dart';

class SegmentationView extends StatelessWidget {
  const SegmentationView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SegmentationProvider>();
    provider.loadModel();

    return Scaffold(
        appBar: AppBar(
          title: const Text('Segmentation Wound'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions:const  [
            ActionButtonSegmentation()
          ],
        ), 
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                  const ImagePreview(),
                  const SizedBox(height: 10,),

                  ElevatedButton(onPressed: (){
                      showModalBottomSheet(context: context, 
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)
                          )
                        ),
                        builder: (context) => ItemBottomSheet(provider: provider));
                  }, child: const Text('Choose picture')),

                  const SizedBox(height: 20,),

                  Consumer<SegmentationProvider>(
                    builder: (c, prov, w)=> prov.processing ? const CircularProgressIndicator() : 
                    (prov.memoryResult == null ? const SizedBox() : Image.memory(prov.memoryResult!))
                  )
              ],
            ),
          ),
        ),
    );
  }
}

class ImagePreview extends StatelessWidget {
  const ImagePreview({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Consumer<SegmentationProvider>(
        builder: (context, prov, w) {
    
          return Stack(
            children: [
              prov.fileImage == null ? Image.asset(Assets.assetsImagesTakepicture) :
                 Image.file(prov.fileImage!, height: 350,),

            ],
          );
        }
      ),
    );
  }
}

class ActionButtonSegmentation extends StatelessWidget {
  const ActionButtonSegmentation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SegmentationProvider>(
      builder: (c, prov,w)=>prov.fileImage!=null ? (
        prov.processing ? const CupertinoActivityIndicator() : 
        IconButton(
            tooltip: 'Start Inference',
            onPressed: (){
                prov.segmentation(prov.fileImage?.path ?? '');
          }, icon: const Icon(Icons.stacked_line_chart_sharp))
          
      ) : const SizedBox());
  }
}

class ItemBottomSheet extends StatelessWidget {
  const ItemBottomSheet({
    super.key,
    required this.provider,
  });

  final SegmentationProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
        children: [
          ListTile(leading: const Icon(Icons.camera), title: const Text('Camera'),
            onTap: (){
                Navigator.pop(context);
                ImagePicker().pickImage(source: ImageSource.camera).then((value) {
                  if(value != null){
                    provider.setFile(File(value.path));
                  }
                });
            },
          ),
          ListTile(leading: const  Icon(Icons.image), title: const Text('Photo'),
            onTap: (){
                Navigator.pop(context);
                ImagePicker().pickImage(source: ImageSource.gallery).then((value) {
                  print(value?.path);
                  if(value != null){
                    provider.setFile(File(value.path));
                  }
                });
            },
          ),
        ],
      );
  }
}