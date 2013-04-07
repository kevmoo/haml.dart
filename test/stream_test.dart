library stream_test;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:bot/bot.dart';
import 'package:unittest/unittest.dart';

import 'package:okoboji/block.dart';

final _rnd = new math.Random();

void main() {
  test('yay', () {

    final target = 30;

    final strStream = getRandomBlockStream(target);
    final byteStream = strStream.transform(new StringEncoder());
    final chunkStream = byteStream.transform(_chunkListStream(100));
    final decodedStream = chunkStream.transform(new StringDecoder());
    final lines = decodedStream.transform(splitLines());
    final magicLines = lines.transform(toLines());
    final flatLines = magicLines.transform(toFlat());
    final blockStream = flatLines.transform(toBlocks());

    return blockStream.toList()
        .then((list) {
          print('');
          print("results...");
          print('');
          print(Block.getString(list));

          var totalCount = list.fold(0, (int v, Block b) => v + b.getTotalCount());
          expect(totalCount, target);
        });
  });
}

StreamTransformer<List, List> _chunkListStream(int chunkSize) {
  assert(chunkSize > 0);
  List buffer;

  return new StreamTransformer<List, List>(
      handleData: (List data, EventSink<List> sink) {
        int index = 0;

        while(index < data.length) {
          if(buffer == null) {
            buffer = new List();
          }

          final startLength = buffer.length;
          assert(startLength < chunkSize);

          buffer.addAll(data.skip(index).take(chunkSize - startLength));
          index += buffer.length - startLength;

          if(buffer.length == chunkSize) {
            sink.add(buffer);
            buffer = null;
          } else {
            break;
          }
        }

      },
      handleDone: (EventSink<List> sink) {
        if(buffer != null && !buffer.isEmpty) {
          assert(buffer.length < chunkSize);
          sink.add(buffer);
        }
        sink.close();
      });
}

Stream<String> getRandomBlockStream(int rowCount) {
  assert(rowCount >= 0);

  final controller = new StreamController();

  var depth = null;

  Future.forEach(new Iterable.generate(rowCount, (e) => e), (i) {
    return Timer.run(() {
      depth = _getDepth(depth);
      String value = 'line $i at depth $depth';
      for(var i = 0; i < depth; i++) {
        value = '  ' + value;
      }
      value = value + '\n';
      controller.add(value);
    });
  }).then((_) {
    controller.close();
  });

  return controller.stream;
}

int _getDepth(int lastDepth) {
  if(lastDepth == null) {
    return 0;
  }
  var flip = lastDepth > 0 ? _rnd.nextInt(3) : _rnd.nextInt(2);

  switch(flip) {
    case 0:
      return lastDepth;
    case 1:
      return lastDepth + 1;
    case 2:
      assert(lastDepth > 0);
      return _rnd.nextInt(lastDepth);
    default:
      throw 'boo!';
  }
}
