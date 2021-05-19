import 'package:flutter_test/flutter_test.dart';

import 'package:talkjs/talkjs.dart';

void main() {
  test('test oneOnOneId', () {
    expect(Talk.oneOnOneId('1234', 'abcd'), '35ec37e6e0ca43ac8ccc');
    expect(Talk.oneOnOneId('abcd', '1234'), '35ec37e6e0ca43ac8ccc');
  });
}
