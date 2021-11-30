import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class Cheers extends StatelessWidget {
  const Cheers({
    Key? key,
    required Stream<QuerySnapshot<Object?>> shakersStream,
  })  : _shakersStream = shakersStream,
        super(key: key);

  final Stream<QuerySnapshot<Object?>> _shakersStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _shakersStream,
      builder: (context, snapshot) {
        return Visibility(
          visible: snapshot.hasData && snapshot.data!.docs.length >= 2,
          child: const Center(
            child: Text('🍻', style: TextStyle(fontSize: 300)),
          ),
        );
      },
    );
  }
}
