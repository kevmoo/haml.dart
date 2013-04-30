import 'package:haml/haml.dart';

void main() {
  print('Sample 1:');
  var input = '%h1 Hello, Haml!';
  var output = hamlStringToHtml(input);
  print(output);

  print('Sample 2:');
  input  =
'''
#content
  .section.draft
    %p.paragraph.example Here's some content
    %img{ :src => 'http://foo.com/img.png', :alt => 'silly' }
  %a(href='http://foo.com') Link body
''';

  output = hamlStringToHtml(input);
  print(output);
}
